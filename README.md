# Hebi

A highly optimized Quickshell setup utilizing native C++ plugins for maximum performance.

## Dependencies

To compile and run the native `HebiPlugin` on Arch Linux, you will need the following dependencies:

```bash
sudo pacman -S cmake make gcc qt6-base qt6-declarative qt6-shadertools qt6-svg libqalculate pipewire aubio 
yay -S libcava
```

### Compiling the Plugin

After installing the dependencies, run the following commands to build the plugin:

```bash
cd plugin
cmake -B build -S . -DVERSION="1.0"
cmake --build build -j$(nproc)
```
