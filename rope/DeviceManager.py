"""
Device Manager for handling NVIDIA CUDA and AMD ROCm GPUs
"""
import torch
import subprocess as sp
from typing import Tuple, Optional
import os
import logging
import onnxruntime


class DeviceManager:
    """Manages GPU device detection and provides unified interface for CUDA and ROCm"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        
        # Check available ONNX Runtime providers
        self._check_onnx_providers()
        
        # Check for force CPU mode
        self.force_cpu = os.environ.get('ROPE_FORCE_CPU', '0') == '1'
        
        if self.force_cpu:
            self.logger.warning("🔧 Force CPU mode enabled via ROPE_FORCE_CPU")
            self.device_type = 'cpu'
            self.device = torch.device('cpu')
            self.providers = ['CPUExecutionProvider']
        else:
            self.device_type = self._detect_device()
            self.device = torch.device(self.device_type)
            self.providers = self._get_providers()
    
    def _check_onnx_providers(self):
        """Check which ONNX Runtime providers are actually available"""
        try:
            available = onnxruntime.get_available_providers()
            self.onnx_providers_available = available
            self.logger.debug(f"ONNX Runtime available providers: {available}")
        except Exception as e:
            self.logger.warning(f"Could not check ONNX Runtime providers: {e}")
            self.onnx_providers_available = ['CPUExecutionProvider']
        
    def _detect_device(self) -> str:
        """Detect available GPU device (CUDA/ROCm) or fallback to CPU"""
        self.logger.debug("Detecting GPU device...")
        
        if torch.cuda.is_available():
            device_name = torch.cuda.get_device_name(0)
            self.logger.debug(f"CUDA device found: {device_name}")
            
            # ROCm shows up as CUDA in PyTorch, but we can detect AMD GPUs by name
            if 'AMD' in device_name or 'Radeon' in device_name:
                print(f"✓ AMD GPU detected: {device_name}")
                print(f"  Using ROCm backend")
                self.logger.info(f"AMD GPU detected: {device_name} (ROCm backend)")
                return 'cuda'
            else:
                print(f"✓ NVIDIA GPU detected: {device_name}")
                print(f"  Using CUDA backend")
                self.logger.info(f"NVIDIA GPU detected: {device_name} (CUDA backend)")
                return 'cuda'
        else:
            print("⚠ No GPU detected, using CPU")
            print("  Warning: CPU inference will be significantly slower")
            self.logger.warning("No GPU detected, using CPU (will be slower)")
            return 'cpu'
    
    def _get_providers(self) -> list:
        """Get ONNX Runtime execution providers based on detected device"""
        if self.device_type == 'cuda':
            device_name = torch.cuda.get_device_name(0)
            if 'AMD' in device_name or 'Radeon' in device_name:
                # AMD GPU - check for DirectML (Windows), MIGraphX (Linux), or ROCm (legacy)
                if 'DmlExecutionProvider' in self.onnx_providers_available:
                    providers = ['DmlExecutionProvider', 'CPUExecutionProvider']
                    self.logger.info(f"ONNX Runtime providers: {providers}")
                    self.logger.info("✓ Using DirectML (Windows GPU acceleration for AMD)")
                    print("✓ Using DirectML GPU acceleration (AMD on Windows)")
                    
                    # CRITICAL: DirectML is incompatible with PyTorch CUDA tensors
                    # Force CPU mode for PyTorch while DirectML handles GPU inference
                    self.logger.info("  Forcing CPU device for PyTorch (DirectML compatibility)")
                    print("  Note: Using CPU tensors with DirectML GPU inference")
                    self.device_type = 'cpu'
                    self.device = torch.device('cpu')
                    
                elif 'MIGraphXExecutionProvider' in self.onnx_providers_available:
                    providers = ['MIGraphXExecutionProvider', 'CPUExecutionProvider']
                    self.logger.info(f"ONNX Runtime providers: {providers}")
                    self.logger.info("✓ Using MIGraphXExecutionProvider (AMD's Linux GPU provider)")
                    print("✓ Using AMD MIGraphX GPU acceleration")
                    return providers
                elif 'ROCMExecutionProvider' in self.onnx_providers_available:
                    providers = ['ROCMExecutionProvider', 'CPUExecutionProvider']
                    self.logger.info(f"ONNX Runtime providers: {providers}")
                    self.logger.warning("⚠ Using deprecated ROCMExecutionProvider - consider upgrading")
                    print("⚠ Using legacy ROCm provider (deprecated)")
                    return providers
                else:
                    # No AMD GPU providers available - must use CPU
                    providers = ['CPUExecutionProvider']
                    # Force CPU mode to avoid device mismatch crashes
                    self.device_type = 'cpu'
                    self.device = torch.device('cpu')
                    self.logger.warning("⚠ No AMD GPU providers available in ONNX Runtime!")
                    self.logger.warning("  PyTorch has ROCm support, but ONNX Runtime does not.")
                    self.logger.warning("  Install onnxruntime with GPU support:")
                    self.logger.warning("    - For Windows: pip install onnxruntime-directml")
                    self.logger.warning("    - For Linux: pip install onnxruntime-rocm")
                    print("⚠ Warning: ONNX Runtime missing AMD GPU support")
                    print("  Falling back to CPU mode (slower)")
                    print("  For GPU acceleration:")
                    print("    - Windows: pip install onnxruntime-directml")
                    print("    - Linux: pip install onnxruntime-rocm")
                return providers
            else:
                # NVIDIA CUDA GPU
                if 'CUDAExecutionProvider' in self.onnx_providers_available:
                    providers = ['CUDAExecutionProvider', 'CPUExecutionProvider']
                    self.logger.info(f"ONNX Runtime providers: {providers}")
                else:
                    providers = ['CPUExecutionProvider']
                    # Force CPU mode to avoid device mismatch crashes
                    self.device_type = 'cpu'
                    self.device = torch.device('cpu')
                    self.logger.warning("⚠ CUDAExecutionProvider not available, using CPU")
                return providers
        else:
            # CPU only
            providers = ['CPUExecutionProvider']
            self.logger.info(f"ONNX Runtime providers: {providers}")
            return providers
    
    def get_detection_device_info(self) -> tuple:
        """
        Get device string and type for face detection.
        Returns (device_str, device_type) tuple.
        """
        return (self.get_device_string(), self.device_type)
    
    def get_device_string(self) -> str:
        """Get device string for PyTorch operations (e.g., 'cuda:0' or 'cpu')"""
        if self.device_type == 'cuda':
            return 'cuda:0'
        return 'cpu'
    
    def get_gpu_memory(self) -> Tuple[int, int]:
        """
        Get GPU memory usage (used, total) in MB
        Returns (0, 0) if GPU is not available or on error
        """
        if self.device_type != 'cuda':
            return 0, 0
        
        try:
            # Try PyTorch's method first (works for both NVIDIA and AMD)
            memory_allocated = torch.cuda.memory_allocated(0) // (1024 * 1024)  # Convert to MB
            memory_reserved = torch.cuda.memory_reserved(0) // (1024 * 1024)  # Convert to MB
            
            # Get total memory
            memory_total = torch.cuda.get_device_properties(0).total_memory // (1024 * 1024)
            
            return memory_reserved, memory_total
        except Exception as e:
            # Fallback to nvidia-smi for NVIDIA GPUs only
            try:
                device_name = torch.cuda.get_device_name(0)
                if 'NVIDIA' in device_name or 'GeForce' in device_name or 'RTX' in device_name:
                    return self._get_nvidia_memory()
            except:
                pass
            
            print(f"Warning: Could not get GPU memory info: {e}")
            return 0, 0
    
    def _get_nvidia_memory(self) -> Tuple[int, int]:
        """Get NVIDIA GPU memory using nvidia-smi (fallback method)"""
        try:
            command = "nvidia-smi --query-gpu=memory.total --format=csv"
            memory_total_info = sp.check_output(command.split()).decode('ascii').split('\n')[:-1][1:]
            memory_total = [int(x.split()[0]) for i, x in enumerate(memory_total_info)]
            
            command = "nvidia-smi --query-gpu=memory.free --format=csv"
            memory_free_info = sp.check_output(command.split()).decode('ascii').split('\n')[:-1][1:]
            memory_free = [int(x.split()[0]) for i, x in enumerate(memory_free_info)]
            
            memory_used = memory_total[0] - memory_free[0]
            return memory_used, memory_total[0]
        except Exception as e:
            print(f"Warning: nvidia-smi failed: {e}")
            return 0, 0
    
    def is_gpu_available(self) -> bool:
        """Check if GPU is available"""
        return self.device_type == 'cuda'
    
    def is_directml(self) -> bool:
        """Check if using DirectML (AMD GPU on Windows)"""
        return 'DmlExecutionProvider' in self.providers
    
    def get_device_info(self) -> dict:
        """Get detailed device information"""
        info = {
            'device_type': self.device_type,
            'device_string': self.get_device_string(),
            'providers': self.providers,
            'gpu_available': self.is_gpu_available()
        }
        
        if self.is_gpu_available():
            info['gpu_name'] = torch.cuda.get_device_name(0)
            info['compute_capability'] = torch.cuda.get_device_capability(0)
            memory_used, memory_total = self.get_gpu_memory()
            info['memory_used_mb'] = memory_used
            info['memory_total_mb'] = memory_total
        
        return info
