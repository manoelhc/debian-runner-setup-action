# Debian Runner Setup Action

A GitHub Action to install common build packages for Debian/Ubuntu runners with built-in `.deb` caching support.

## Features

- **Package Presets**: Choose from pre-configured package sets or specify custom packages
- **Smart Caching**: Uses a "hollow package" mechanism to track installed packages and skip redundant installations
- **Multiple Presets**: `minimal`, `python`, `ruby`, `rust`, `go`, `node`, `full`

## Usage

### Basic Usage

```yaml
- uses: manoelhc/debian-runner-setup-action@v2
```

### Specify Package Preset

```yaml
- uses: manoelhc/debian-runner-setup-action@v2
  with:
    packages: python
```

### Custom Packages

```yaml
- uses: manoelhc/debian-runner-setup-action@v2
  with:
    packages: build-essential cmake libssl-dev
```

### Disable Caching

```yaml
- uses: manoelhc/debian-runner-setup-action@v2
  with:
    cache: false
```

### Using Sudo

```yaml
- uses: manoelhc/debian-runner-setup-action@v2
  with:
    sudo: true
    packages: python
```

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `packages` | Package preset (`minimal`, `python`, `ruby`, `rust`, `go`, `node`, `full`) or space-separated package list | `full` |
| `cache` | Enable `.deb` caching | `true` |
| `cache-key` | Custom cache key suffix | `''` |
| `sudo` | Run installation commands with sudo | `false` |

## Package Presets

| Preset | Packages |
|--------|----------|
| `minimal` | build-essential, git, curl, wget |
| `python` | build-essential, git, curl, wget, libssl-dev, libffi-dev, libreadline-dev, libsqlite3-dev, libbz2-dev, liblzma-dev, libzstd-dev, zlib1g-dev, pkg-config |
| `ruby` | build-essential, git, curl, wget, libssl-dev, libreadline-dev, libyaml-dev, libgmp-dev, libatomic1 |
| `rust` | build-essential, git, curl, wget, pkg-config, libssl-dev, libffi-dev |
| `go` | build-essential, git, curl, wget |
| `node` | build-essential, git, curl, wget, libssl-dev, libcrypto3-dev, libpp-dev, libnghttp2-dev, libzstd-dev |
| `full` | All packages from all presets |

## How It Works

1. **Cache Check**: If caching is enabled, the action first checks if a "hollow package" marker exists indicating packages are already installed
2. **Package Installation**: If not cached, installs the requested packages using `apt-get`
3. **Cleanup**: Removes package lists and cleans up to minimize cache size
4. **Marker Creation**: Creates a hollow package marker to track installation for future runs

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

ManoelHC
