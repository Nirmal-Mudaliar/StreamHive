# Set execution policy for this process to allow script execution
Set-ExecutionPolicy Bypass -Scope Process -Force

# Force the console to stay open
$Host.UI.RawUI.WindowTitle = "Stream Hive Microservices Setup"

# Function to check if script is running as administrator
# Ensures the script has the necessary privileges to execute critical operations
function Test-Admin {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to wait for user input before closing - more robust version
function Wait-ForExit {
    param([string]$Message = "Press CTRL+C to exit...")
    Write-Output ""
    Write-Output $Message
    try {
        if ($Host.UI.RawUI.KeyAvailable) {
            # Clear any pending keys
            while ($Host.UI.RawUI.KeyAvailable) { $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
        }
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } catch {
        try {
            # Alternative method
            $null = Read-Host "Press Enter to continue"
        } catch {
            # Last resort - just pause
            Start-Sleep -Seconds 3
            Write-Output "Exiting in 3 seconds..."
        }
    }
}

# Add this at the very beginning to prevent auto-close
if ($MyInvocation.InvocationName -ne '.') {
    # Script was run directly, not dot-sourced
    $KeepOpen = $true
}

try {
    # Exit if not running as administrator
    # Prevents execution if the script lacks admin privileges
    if (-not (Test-Admin)) {
        Write-Output "This script must be run as Administrator. Please restart PowerShell as Administrator and rerun the script."
        Wait-ForExit
        exit 1
    }

    # Check if Go is installed
    # Installs Go programming language if not already present
    $goInstalled = $false
    if (Get-Command go -ErrorAction SilentlyContinue) {
        # Output message if Go is already installed
        Write-Output "Go is already installed."
        $goInstalled = $true
    } else {
        # Install Go using winget if not installed
        Write-Output "Go is not installed. Installing..."
        winget install -e --id Golang.Go
    }

    # Verify Go installation
    # Confirms successful installation of Go
    if (-not $goInstalled -and (Get-Command go -ErrorAction SilentlyContinue)) {
        # Output success message if Go is installed successfully
        Write-Output "Go installation successful."
    } elseif (-not $goInstalled) {
        # Output failure message if Go installation fails
        Write-Output "Go installation failed. Please install manually."
    }

    # Install required Go packages if Go is available
    # These packages are essential for protocol buffers, gRPC, SQL code generation, and API documentation
    if (Get-Command go -ErrorAction SilentlyContinue) {
        Write-Output "Checking and installing required Go packages..."

        try {
            # Check and install protoc-gen-go
            if (Get-Command protoc-gen-go -ErrorAction SilentlyContinue) {
                Write-Output "protoc-gen-go is already installed."
            } else {
                Write-Output "Installing protoc-gen-go..."
                go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
            }

            # Check and install protoc-gen-go-grpc
            if (Get-Command protoc-gen-go-grpc -ErrorAction SilentlyContinue) {
                Write-Output "protoc-gen-go-grpc is already installed."
            } else {
                Write-Output "Installing protoc-gen-go-grpc..."
                go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
            }

            # Check and install sqlc
            if (Get-Command sqlc -ErrorAction SilentlyContinue) {
                Write-Output "sqlc is already installed."
            } else {
                Write-Output "Installing sqlc..."
                go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
            }

            # Check and install swag
            if (Get-Command swag -ErrorAction SilentlyContinue) {
                Write-Output "swag is already installed."
            } else {
                Write-Output "Installing swag..."
                go install github.com/swaggo/swag/cmd/swag@latest
            }

            # Check and install gowsdl
            if (Get-Command gowsdl -ErrorAction SilentlyContinue) {
                Write-Output "gowsdl is already installed."
            } else {
                Write-Output "Installing gowsdl..."
                go install github.com/hooklift/gowsdl/cmd/gowsdl@latest
            }

            Write-Output "All required Go packages are now available."
        }
        catch {
            Write-Output "Some Go packages may have failed to install. Please run the go install commands manually if needed."
        }
    } else {
        Write-Output "Go is not available. Skipping Go package installations."
    }

    # Check if Chocolatey is installed
    # Installs Chocolatey package manager if not already present
    if (-not (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe")) {
        # Install Chocolatey using the official script if not installed
        Write-Output "Chocolatey is not installed. Installing..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        Write-Output "Chocolatey installed successfully. Restarting PowerShell to continue..."
        Wait-ForExit "Press any key to restart and continue the installation..."

        # Get the current script path
        $scriptPath = $MyInvocation.MyCommand.Path

        # Start a new elevated PowerShell session with the same script
        Start-Process PowerShell -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        exit
    } else {
        # Output message if Chocolatey is already installed
        Write-Output "Chocolatey is already installed."
    }

    # Upgrade Chocolatey to ensure it is up-to-date
    # Keeps Chocolatey package manager updated
    Write-Output "Upgrading Chocolatey..."
    choco upgrade chocolatey -y

    # Refresh environment variables to ensure choco is in PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    # Check if Make is installed
    # Installs Make build tool if not already present
    $makeInstalled = $false
    if (Get-Command make -ErrorAction SilentlyContinue) {
        # Output message if Make is already installed
        Write-Output "Make is already installed."
        $makeInstalled = $true
    } else {
        # Install Make using Chocolatey if not installed
        Write-Output "Make is not installed. Installing via Chocolatey..."
        choco install make -y
    }

    # Verify Make installation
    # Confirms successful installation of Make
    if (-not $makeInstalled -and (Get-Command make -ErrorAction SilentlyContinue)) {
        # Output success message if Make is installed successfully
        Write-Output "Make installation successful."
    } elseif (-not $makeInstalled) {
        # Output failure message if Make installation fails
        Write-Output "Make installation failed. Please install manually."
    }

    # Check if Protobuf is installed
    # Protobuf is a protocol buffer compiler used for serializing structured data
    $protobufInstalled = $false
    if (Get-Command protoc -ErrorAction SilentlyContinue) {
        # Output message if Protobuf is already installed
        Write-Output "Protobuf is already installed."
        $protobufInstalled = $true
    } else {
        # Install Protobuf using winget if not installed
        Write-Output "Protobuf is not installed. Installing via winget..."
        winget install protobuf
    }

    # Verify Protobuf installation
    # Confirms successful installation of Protobuf
    if (-not $protobufInstalled -and (Get-Command protoc -ErrorAction SilentlyContinue)) {
        # Output success message if Protobuf is installed successfully
        Write-Output "Protobuf installation successful."
    } elseif (-not $protobufInstalled) {
        # Output failure message if Protobuf installation fails
        Write-Output "Protobuf installation failed. Please install manually."
    }

    # Check if mkcert is installed
    # mkcert is a tool for creating locally-trusted development certificates
    $mkcertInstalled = $false
    if (Get-Command mkcert -ErrorAction SilentlyContinue) {
        # Output message if mkcert is already installed
        Write-Output "mkcert is already installed."
        $mkcertInstalled = $true
    } else {
        # Install mkcert using Chocolatey if not installed
        Write-Output "mkcert is not installed. Installing via Chocolatey..."
        choco install mkcert -y
    }

    # Verify mkcert installation
    # Confirms successful installation of mkcert
    if (-not $mkcertInstalled -and (Get-Command mkcert -ErrorAction SilentlyContinue)) {
        # Output success message if mkcert is installed successfully
        Write-Output "mkcert installation successful."
    } elseif (-not $mkcertInstalled) {
        # Output failure message if mkcert installation fails
        Write-Output "mkcert installation failed. Please install manually."
    }

    # Check if Azure CLI is installed
    # Azure CLI is a command-line interface for managing Azure resources
    $azureCliInstalled = $false
    if (Get-Command az -ErrorAction SilentlyContinue) {
        # Output message if Azure CLI is already installed
        Write-Output "Azure CLI is already installed."
        $azureCliInstalled = $true
    } else {
        # Install Azure CLI using winget if not installed
        Write-Output "Azure CLI is not installed. Installing via winget..."
        winget install -e --id Microsoft.AzureCLI
    }

    # Verify Azure CLI installation
    # Confirms successful installation of Azure CLI
    if (-not $azureCliInstalled -and (Get-Command az -ErrorAction SilentlyContinue)) {
        # Output success message if Azure CLI is installed successfully
        Write-Output "Azure CLI installation successful."
        Write-Output "You can now use 'az login' to authenticate with Azure."
        Write-Output "Run 'az --version' to verify the installation."
    } elseif (-not $azureCliInstalled) {
        # Output failure message if Azure CLI installation fails
        Write-Output "Azure CLI installation failed. Please install manually from https://aka.ms/installazurecliwindows"
    }

    # Refresh environment variables again to ensure all new tools are in PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    # Optional: Install Azure CLI extensions commonly used for containerization
    # These extensions provide additional functionality for working with Azure Container Registry and Kubernetes
    if ($azureCliInstalled -or (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Output "Installing common Azure CLI extensions for containerization..."

        try {
            # Install Azure Container Registry extension
            az extension add --name acr --only-show-errors
            Write-Output "Azure Container Registry extension installed."

            # Install Azure Kubernetes Service extension
            az extension add --name aks-preview --only-show-errors
            Write-Output "Azure Kubernetes Service extension installed."
        }
        catch {
            Write-Output "Some Azure CLI extensions may have failed to install. This is optional and won't affect basic functionality."
        }
    }

    Write-Output ""
    Write-Output "Setup complete! All required tools should now be installed."
    Write-Output "You may need to restart your terminal/PowerShell session for all changes to take effect."
    Write-Output ""
    Write-Output "Next steps:"
    Write-Output "1. Run 'az login' to authenticate with Azure"
    Write-Output "2. Run 'make --version' to verify Make installation"
    Write-Output "3. Run 'go version' to verify Go installation"
    Write-Output "4. Run 'protoc --version' to verify Protobuf installation"
    Write-Output "5. Run 'mkcert -version' to verify mkcert installation"
    Write-Output "6. Run 'az --version' to verify Azure CLI installation"

} catch {
    Write-Output ""
    Write-Output "An error occurred during setup:"
    Write-Output $_.Exception.Message
    Write-Output ""
    Write-Output "Please check the error above and run the script again."
} finally {
    # Force console to stay open
    if ($KeepOpen -or $true) {
        Wait-ForExit
    }
}

# Additional safety net - this should never be reached but ensures the script doesn't close
Write-Output "Script execution completed."
Start-Sleep -Seconds 1