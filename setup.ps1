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


# SIG # Begin signature block
# MIItswYJKoZIhvcNAQcCoIItpDCCLaACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD26vpB6D8J82yF
# xC8bWNFVvt+Wel+awDyvCgEZkACm16CCEnkwggVvMIIEV6ADAgECAhBI/JO0YFWU
# jTanyYqJ1pQWMA0GCSqGSIb3DQEBDAUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQI
# DBJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoM
# EUNvbW9kbyBDQSBMaW1pdGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2Vy
# dmljZXMwHhcNMjEwNTI1MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjBWMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMS0wKwYDVQQDEyRTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQCN55QSIgQkdC7/FiMCkoq2rjaFrEfUI5ErPtx94jGgUW+s
# hJHjUoq14pbe0IdjJImK/+8Skzt9u7aKvb0Ffyeba2XTpQxpsbxJOZrxbW6q5KCD
# J9qaDStQ6Utbs7hkNqR+Sj2pcaths3OzPAsM79szV+W+NDfjlxtd/R8SPYIDdub7
# P2bSlDFp+m2zNKzBenjcklDyZMeqLQSrw2rq4C+np9xu1+j/2iGrQL+57g2extme
# me/G3h+pDHazJyCh1rr9gOcB0u/rgimVcI3/uxXP/tEPNqIuTzKQdEZrRzUTdwUz
# T2MuuC3hv2WnBGsY2HH6zAjybYmZELGt2z4s5KoYsMYHAXVn3m3pY2MeNn9pib6q
# RT5uWl+PoVvLnTCGMOgDs0DGDQ84zWeoU4j6uDBl+m/H5x2xg3RpPqzEaDux5mcz
# mrYI4IAFSEDu9oJkRqj1c7AGlfJsZZ+/VVscnFcax3hGfHCqlBuCF6yH6bbJDoEc
# QNYWFyn8XJwYK+pF9e+91WdPKF4F7pBMeufG9ND8+s0+MkYTIDaKBOq3qgdGnA2T
# OglmmVhcKaO5DKYwODzQRjY1fJy67sPV+Qp2+n4FG0DKkjXp1XrRtX8ArqmQqsV/
# AZwQsRb8zG4Y3G9i/qZQp7h7uJ0VP/4gDHXIIloTlRmQAOka1cKG8eOO7F/05QID
# AQABo4IBEjCCAQ4wHwYDVR0jBBgwFoAUoBEKIz6W8Qfs4q8p74Klf9AwpLQwHQYD
# VR0OBBYEFDLrkpr/NZZILyhAQnAgNpFcF4XmMA4GA1UdDwEB/wQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MBMGA1UdJQQMMAoGCCsGAQUFBwMDMBsGA1UdIAQUMBIwBgYE
# VR0gADAIBgZngQwBBAEwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21v
# ZG9jYS5jb20vQUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNAYIKwYBBQUHAQEE
# KDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJKoZI
# hvcNAQEMBQADggEBABK/oe+LdJqYRLhpRrWrJAoMpIpnuDqBv0WKfVIHqI0fTiGF
# OaNrXi0ghr8QuK55O1PNtPvYRL4G2VxjZ9RAFodEhnIq1jIV9RKDwvnhXRFAZ/ZC
# J3LFI+ICOBpMIOLbAffNRk8monxmwFE2tokCVMf8WPtsAO7+mKYulaEMUykfb9gZ
# pk+e96wJ6l2CxouvgKe9gUhShDHaMuwV5KZMPWw5c9QLhTkg4IUaaOGnSDip0TYl
# d8GNGRbFiExmfS9jzpjoad+sPKhdnckcW67Y8y90z7h+9teDnRGWYpquRRPaf9xH
# +9/DUp/mBlXpnYzyOmJRvOwkDynUWICE5EV7WtgwggYcMIIEBKADAgECAhAz1wio
# kUBTGeKlu9M5ua1uMA0GCSqGSIb3DQEBDAUAMFYxCzAJBgNVBAYTAkdCMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxLTArBgNVBAMTJFNlY3RpZ28gUHVibGljIENv
# ZGUgU2lnbmluZyBSb290IFI0NjAeFw0yMTAzMjIwMDAwMDBaFw0zNjAzMjEyMzU5
# NTlaMFcxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxLjAs
# BgNVBAMTJVNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBFViBSMzYwggGi
# MA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQC70f4et0JbePWQp64sg/GNIdMw
# hoV739PN2RZLrIXFuwHP4owoEXIEdiyBxasSekBKxRDogRQ5G19PB/YwMDB/NSXl
# wHM9QAmU6Kj46zkLVdW2DIseJ/jePiLBv+9l7nPuZd0o3bsffZsyf7eZVReqskmo
# PBBqOsMhspmoQ9c7gqgZYbU+alpduLyeE9AKnvVbj2k4aOqlH1vKI+4L7bzQHkND
# brBTjMJzKkQxbr6PuMYC9ruCBBV5DFIg6JgncWHvL+T4AvszWbX0w1Xn3/YIIq62
# 0QlZ7AGfc4m3Q0/V8tm9VlkJ3bcX9sR0gLqHRqwG29sEDdVOuu6MCTQZlRvmcBME
# Jd+PuNeEM4xspgzraLqVT3xE6NRpjSV5wyHxNXf4T7YSVZXQVugYAtXueciGoWnx
# G06UE2oHYvDQa5mll1CeHDOhHu5hiwVoHI717iaQg9b+cYWnmvINFD42tRKtd3V6
# zOdGNmqQU8vGlHHeBzoh+dYyZ+CcblSGoGSgg8sCAwEAAaOCAWMwggFfMB8GA1Ud
# IwQYMBaAFDLrkpr/NZZILyhAQnAgNpFcF4XmMB0GA1UdDgQWBBSBMpJBKyjNRsjE
# osYqORLsSKk/FDAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADAT
# BgNVHSUEDDAKBggrBgEFBQcDAzAaBgNVHSAEEzARMAYGBFUdIAAwBwYFZ4EMAQMw
# SwYDVR0fBEQwQjBAoD6gPIY6aHR0cDovL2NybC5zZWN0aWdvLmNvbS9TZWN0aWdv
# UHVibGljQ29kZVNpZ25pbmdSb290UjQ2LmNybDB7BggrBgEFBQcBAQRvMG0wRgYI
# KwYBBQUHMAKGOmh0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1B1YmxpY0Nv
# ZGVTaWduaW5nUm9vdFI0Ni5wN2MwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLnNl
# Y3RpZ28uY29tMA0GCSqGSIb3DQEBDAUAA4ICAQBfNqz7+fZyWhS38Asd3tj9lwHS
# /QHumS2G6Pa38Dn/1oFKWqdCSgotFZ3mlP3FaUqy10vxFhJM9r6QZmWLLXTUqwj3
# ahEDCHd8vmnhsNufJIkD1t5cpOCy1rTP4zjVuW3MJ9bOZBHoEHJ20/ng6SyJ6UnT
# s5eWBgrh9grIQZqRXYHYNneYyoBBl6j4kT9jn6rNVFRLgOr1F2bTlHH9nv1HMePp
# GoYd074g0j+xUl+yk72MlQmYco+VAfSYQ6VK+xQmqp02v3Kw/Ny9hA3s7TSoXpUr
# OBZjBXXZ9jEuFWvilLIq0nQ1tZiao/74Ky+2F0snbFrmuXZe2obdq2TWauqDGIgb
# MYL1iLOUJcAhLwhpAuNMu0wqETDrgXkG4UGVKtQg9guT5Hx2DJ0dJmtfhAH2KpnN
# r97H8OQYok6bLyoMZqaSdSa+2UA1E2+upjcaeuitHFFjBypWBmztfhj24+xkc6Zt
# CDaLrw+ZrnVrFyvCTWrDUUZBVumPwo3/E3Gb2u2e05+r5UWmEsUUWlJBl6MGAAjF
# 5hzqJ4I8O9vmRsTvLQA1E802fZ3lqicIBczOwDYOSxlP0GOabb/FKVMxItt1UHeG
# 0PL4au5rBhs+hSMrl8h+eplBDN1Yfw6owxI9OjWb4J0sjBeBVESoeh2YnZZ/WVim
# VGX/UUIL+Efrz/jlvzCCBuIwggVKoAMCAQICEQDKdk9AjijtRDS0C2tK7FzrMA0G
# CSqGSIb3DQEBCwUAMFcxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExp
# bWl0ZWQxLjAsBgNVBAMTJVNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBF
# ViBSMzYwHhcNMjMwOTI5MDAwMDAwWhcNMjYwOTI4MjM1OTU5WjCBrTEQMA4GA1UE
# BRMHNzU4MTczNTETMBEGCysGAQQBgjc8AgEDEwJVUzEZMBcGCysGAQQBgjc8AgEC
# EwhEZWxhd2FyZTEdMBsGA1UEDxMUUHJpdmF0ZSBPcmdhbml6YXRpb24xCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRMwEQYDVQQKDApWYWxvcnggSW5j
# MRMwEQYDVQQDDApWYWxvcnggSW5jMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAtZz87uUssyUjaK/GHnfwYddI+hnNrdsn8pC7Kv8tSkz8nQc0lg7irE/j
# s5xM6oMad1+PpiqKdUxogFZjZjDmobCaSHWaVV6JVT4IaKBj1+Z2ropLs9Nas+kH
# dGv+GYH6c9fNPAVAoAkYBEeikIMPf4nNdBceESpROeBSZkk445s3Z/EWi22hZdPk
# R/h2RXTQ5RGwjJV/NVPv4Zj1pVoTF/8MRR80xqsA+iQRAN5ok18JoyqsrMRc8Pg8
# 5wl0Sl1qdO0ZcZs+2UzQ2qNrWy98oam9KBSRWmbQE/GY4uUMOrvXT4dxtmCwNM2H
# BtGQ3tD4DZ3AOYhNnw1NMpgLFN4E/r5xVx8/gy395xnbluVHuhSynrLxbAW89VvU
# sv5vnhIGF0sVGf92Zfe0Zulq7usTI7fZF09Ttogz3k5WBxkPgjcfmaesN9usW1Dg
# 4c8PDIwRrvNmr3Yi3zsKYgbaRlSBllqjkqnD8D6A2QDUKHVb+dwXu9RyZAzTMyh7
# EThz5pewDeZh0mCcCiPqn/10uOxH/ihqgHLKRPXrpKpdoixPwcE46dnqotV199WL
# Iz+RxXOwhRATxUlUEtJ66doCTb2XPOroj9oa8BWqjTCvkab+ijO36WDj6Z2/VXJI
# KHxNDNRWhKURX6boNdt8Z0ZQNRms27PYdtTfpinBukVCyWU0rhsCAwEAAaOCAdAw
# ggHMMB8GA1UdIwQYMBaAFIEykkErKM1GyMSixio5EuxIqT8UMB0GA1UdDgQWBBTS
# IopJxE0QpWNjjUFvzfa0xQn8vzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIw
# ADATBgNVHSUEDDAKBggrBgEFBQcDAzBJBgNVHSAEQjBAMDUGDCsGAQQBsjEBAgEG
# ATAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQUzAHBgVngQwB
# AzBLBgNVHR8ERDBCMECgPqA8hjpodHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3Rp
# Z29QdWJsaWNDb2RlU2lnbmluZ0NBRVZSMzYuY3JsMHsGCCsGAQUFBwEBBG8wbTBG
# BggrBgEFBQcwAoY6aHR0cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUHVibGlj
# Q29kZVNpZ25pbmdDQUVWUjM2LmNydDAjBggrBgEFBQcwAYYXaHR0cDovL29jc3Au
# c2VjdGlnby5jb20wQgYDVR0RBDswOaAjBggrBgEFBQcIA6AXMBUME1VTLURFTEFX
# QVJFLTc1ODE3MzWBEnN1cHBvcnRAdmFsb3J4LmNvbTANBgkqhkiG9w0BAQsFAAOC
# AYEAlqMPBeVgWYnvY7R0uQWFs3KX9lhP+4BJ/8mwec42EYzY6zXGE5yz+EHSGSBB
# cc+EeVSqlz2UNw2GVvjuBkzUHCte+fwqMhgtviq1FU3++wS3qjapxY6kl9Z7NGFt
# dt4d6L4l643NKpRTVpOM7xAKxRwrl2NRUlnm6hsmwZzuu8L6WE5MuENOcu6mo2EY
# 8o1eJ1Brlycf/h1aMhIADn0AJveO5nNiY142V695zqVa9kTg8NJEmv1im31bhmCf
# W/S0vVO6YdjdMej/meZWNAjSemW+alnmzqxAAZgF3etdSH2GWVX74xFN+TUS37Wh
# fz1fP0pwH+YG2sa3FsYS+lmaSHt3W/8qd9TnfdEYWDVzL5P8zQHbxImJZKERdwbJ
# lWJs27VKXcq/lRYqbzZgzhMyfXvdPCMd9/WIrxSwVKrQfJyUqmwhr9t7MmHzSHkg
# 4E1mq7WnSKTrow30IgeQStoK/O3fhYOkMiODT7MrGz/EhguJhwOTAQA9cHzRkeoB
# hxhoMYIakDCCGowCAQEwbDBXMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGln
# byBMaW1pdGVkMS4wLAYDVQQDEyVTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcg
# Q0EgRVYgUjM2AhEAynZPQI4o7UQ0tAtrSuxc6zANBglghkgBZQMEAgEFAKB8MBAG
# CisGAQQBgjcCAQwxAjAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisG
# AQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCCZZOOZuObo
# kJX3DhSQ9pu2JZ7T9+egAeFTwTRRS6P17jANBgkqhkiG9w0BAQEFAASCAgAcNA1h
# 4/sJEIxjSqJNWwGwa0GdIHmW5jioQrMe40bWIRknf2Qau/Sxb1Q9CFqrkuk193+J
# nk/M6xRbZQTuBQsEtAxnsC8up05+vQZwGQxPqcZxMvV+UbfnPL8MepqJeBLowd70
# eqS9b5z7p1agc+ny4lNk9BwQv1bf5HQzTQv9oOeCqigHv0gjXC2VzElNd22UbZyz
# Ep2jdOuiAS9YZxbgzuBtpcfUMgNd2sr44GR7G0SoRjkHhrUv4gAKBnZiZjNdS3Hs
# NoNJRaHX/bh4fMIq6NKcVLS7ie8OF6rxPn4xwTfHE8I541hJ9poFNFxU64BNUT0d
# fCLJohsWITnckYtbG5bt48taCD3xuOCtkqPTI51UurCcHInoK4MCxYbbTYTKvuq4
# g3ac5SHtY4bT1Hx5H9tcyu0p1WOz+xkJq68qh8ArJqLmmaExiK1uw51hbrxs2gOg
# I/OBJwSx/+HSojorrAzGL99uOx3ynUXKdPDYsFyyn7guOSW5d8j+5doZzczl3i0Y
# 8SfJbM6ncaksLMb1XPlSwLUpUTSWw4lg6IFwrLlk6WFI42XSJSSz8Hcl4e0+PWEF
# H1Cwn2h5B00b2N7WiNHo13U3ti4gvzPiSiqucVg0Fp5DDL0XfewgH0fiohI2Q1vt
# A8n871pCylc81R7HPUEVIeQscruGkcLwYExgUaGCF3cwghdzBgorBgEEAYI3AwMB
# MYIXYzCCF18GCSqGSIb3DQEHAqCCF1AwghdMAgEDMQ8wDQYJYIZIAWUDBAIBBQAw
# eAYLKoZIhvcNAQkQAQSgaQRnMGUCAQEGCWCGSAGG/WwHATAxMA0GCWCGSAFlAwQC
# AQUABCBs/DDhf0KBLCreB/gMfCBNd/NDw1KeP60hcEKWTJkrggIRAMlYBVWDP6PC
# B1QLN9htA8sYDzIwMjUxMTE5MDExODEyWqCCEzowggbtMIIE1aADAgECAhAKgO8Y
# S43xBYLRxHanlXRoMA0GCSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBH
# NCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwHhcNMjUwNjA0
# MDAwMDAwWhcNMzYwOTAzMjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMO
# RGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFNIQTI1NiBSU0E0MDk2
# IFRpbWVzdGFtcCBSZXNwb25kZXIgMjAyNSAxMIICIjANBgkqhkiG9w0BAQEFAAOC
# Ag8AMIICCgKCAgEA0EasLRLGntDqrmBWsytXum9R/4ZwCgHfyjfMGUIwYzKomd8U
# 1nH7C8Dr0cVMF3BsfAFI54um8+dnxk36+jx0Tb+k+87H9WPxNyFPJIDZHhAqlUPt
# 281mHrBbZHqRK71Em3/hCGC5KyyneqiZ7syvFXJ9A72wzHpkBaMUNg7MOLxI6E9R
# aUueHTQKWXymOtRwJXcrcTTPPT2V1D/+cFllESviH8YjoPFvZSjKs3SKO1QNUdFd
# 2adw44wDcKgH+JRJE5Qg0NP3yiSyi5MxgU6cehGHr7zou1znOM8odbkqoK+lJ25L
# CHBSai25CFyD23DZgPfDrJJJK77epTwMP6eKA0kWa3osAe8fcpK40uhktzUd/Yk0
# xUvhDU6lvJukx7jphx40DQt82yepyekl4i0r8OEps/FNO4ahfvAk12hE5FVs9HVV
# WcO5J4dVmVzix4A77p3awLbr89A90/nWGjXMGn7FQhmSlIUDy9Z2hSgctaepZTd0
# ILIUbWuhKuAeNIeWrzHKYueMJtItnj2Q+aTyLLKLM0MheP/9w6CtjuuVHJOVoIJ/
# DtpJRE7Ce7vMRHoRon4CWIvuiNN1Lk9Y+xZ66lazs2kKFSTnnkrT3pXWETTJkhd7
# 6CIDBbTRofOsNyEhzZtCGmnQigpFHti58CSmvEyJcAlDVcKacJ+A9/z7eacCAwEA
# AaOCAZUwggGRMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFOQ7/PIx7f391/ORcWMZ
# UEPPYYzoMB8GA1UdIwQYMBaAFO9vU0rp5AZ8esrikFb2L9RJ7MtOMA4GA1UdDwEB
# /wQEAwIHgDAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDCBlQYIKwYBBQUHAQEEgYgw
# gYUwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBdBggrBgEF
# BQcwAoZRaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3Rl
# ZEc0VGltZVN0YW1waW5nUlNBNDA5NlNIQTI1NjIwMjVDQTEuY3J0MF8GA1UdHwRY
# MFYwVKBSoFCGTmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0
# ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNybDAgBgNVHSAE
# GTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAGUq
# rfEcJwS5rmBB7NEIRJ5jQHIh+OT2Ik/bNYulCrVvhREafBYF0RkP2AGr181o2YWP
# oSHz9iZEN/FPsLSTwVQWo2H62yGBvg7ouCODwrx6ULj6hYKqdT8wv2UV+Kbz/3Im
# ZlJ7YXwBD9R0oU62PtgxOao872bOySCILdBghQ/ZLcdC8cbUUO75ZSpbh1oipOhc
# UT8lD8QAGB9lctZTTOJM3pHfKBAEcxQFoHlt2s9sXoxFizTeHihsQyfFg5fxUFEp
# 7W42fNBVN4ueLaceRf9Cq9ec1v5iQMWTFQa0xNqItH3CPFTG7aEQJmmrJTV3Qhtf
# parz+BW60OiMEgV5GWoBy4RVPRwqxv7Mk0Sy4QHs7v9y69NBqycz0BZwhB9WOfOu
# /CIJnzkQTwtSSpGGhLdjnQ4eBpjtP+XB3pQCtv4E5UCSDag6+iX8MmB10nfldPF9
# SVD7weCC3yXZi/uuhqdwkgVxuiMFzGVFwYbQsiGnoa9F5AaAyBjFBtXVLcKtapnM
# G3VH3EmAp/jsJ3FVF3+d1SVDTmjFjLbNFZUWMXuZyvgLfgyPehwJVxwC+UpX2MSe
# y2ueIu9THFVkT+um1vshETaWyQo8gmBto/m3acaP9QsuLj3FNwFlTxq25+T4QwX9
# xa6ILs84ZPvmpovq90K8eWyG2N01c4IhSOxqt81nMIIGtDCCBJygAwIBAgIQDces
# VwX/IZkuQEMiDDpJhjANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMG
# A1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEw
# HwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjUwNTA3MDAwMDAw
# WhcNMzgwMTE0MjM1OTU5WjBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNl
# cnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1w
# aW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMIICIjANBgkqhkiG9w0BAQEFAAOC
# Ag8AMIICCgKCAgEAtHgx0wqYQXK+PEbAHKx126NGaHS0URedTa2NDZS1mZaDLFTt
# Q2oRjzUXMmxCqvkbsDpz4aH+qbxeLho8I6jY3xL1IusLopuW2qftJYJaDNs1+JH7
# Z+QdSKWM06qchUP+AbdJgMQB3h2DZ0Mal5kYp77jYMVQXSZH++0trj6Ao+xh/AS7
# sQRuQL37QXbDhAktVJMQbzIBHYJBYgzWIjk8eDrYhXDEpKk7RdoX0M980EpLtlrN
# yHw0Xm+nt5pnYJU3Gmq6bNMI1I7Gb5IBZK4ivbVCiZv7PNBYqHEpNVWC2ZQ8Bbfn
# FRQVESYOszFI2Wv82wnJRfN20VRS3hpLgIR4hjzL0hpoYGk81coWJ+KdPvMvaB0W
# kE/2qHxJ0ucS638ZxqU14lDnki7CcoKCz6eum5A19WZQHkqUJfdkDjHkccpL6uoG
# 8pbF0LJAQQZxst7VvwDDjAmSFTUms+wV/FbWBqi7fTJnjq3hj0XbQcd8hjj/q8d6
# ylgxCZSKi17yVp2NL+cnT6Toy+rN+nM8M7LnLqCrO2JP3oW//1sfuZDKiDEb1AQ8
# es9Xr/u6bDTnYCTKIsDq1BtmXUqEG1NqzJKS4kOmxkYp2WyODi7vQTCBZtVFJfVZ
# 3j7OgWmnhFr4yUozZtqgPrHRVHhGNKlYzyjlroPxul+bgIspzOwbtmsgY1MCAwEA
# AaOCAV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFO9vU0rp5AZ8
# esrikFb2L9RJ7MtOMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4G
# A1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRr
# MGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEF
# BQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3Rl
# ZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZn
# gQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQAXzvsWgBz+Bz0R
# dnEwvb4LyLU0pn/N0IfFiBowf0/Dm1wGc/Do7oVMY2mhXZXjDNJQa8j00DNqhCT3
# t+s8G0iP5kvN2n7Jd2E4/iEIUBO41P5F448rSYJ59Ib61eoalhnd6ywFLerycvZT
# Az40y8S4F3/a+Z1jEMK/DMm/axFSgoR8n6c3nuZB9BfBwAQYK9FHaoq2e26MHvVY
# 9gCDA/JYsq7pGdogP8HRtrYfctSLANEBfHU16r3J05qX3kId+ZOczgj5kjatVB+N
# dADVZKON/gnZruMvNYY2o1f4MXRJDMdTSlOLh0HCn2cQLwQCqjFbqrXuvTPSegOO
# zr4EWj7PtspIHBldNE2K9i697cvaiIo2p61Ed2p8xMJb82Yosn0z4y25xUbI7GIN
# /TpVfHIqQ6Ku/qjTY6hc3hsXMrS+U0yy+GWqAXam4ToWd2UQ1KYT70kZjE4YtL8P
# bzg0c1ugMZyZZd/BdHLiRu7hAWE6bTEm4XYRkA6Tl4KSFLFk43esaUeqGkH/wyW4
# N7OigizwJWeukcyIPbAvjSabnf7+Pu0VrFgoiovRDiyx3zEdmcif/sYQsfch28bZ
# eUz2rtY/9TCA6TD8dC3JE3rYkrhLULy7Dc90G6e8BlqmyIjlgp2+VqsS9/wQD7yF
# ylIz0scmbKvFoW2jNrbM1pD2T7m3XDCCBY0wggR1oAMCAQICEA6bGI750C3n79tQ
# 4ghAGFowDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERp
# Z2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMb
# RGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAwMFoXDTMx
# MTEwOTIzNTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IElu
# YzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQg
# VHJ1c3RlZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# v+aQc2jeu+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuEDcQwH/Mb
# pDgW61bGl20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNwwrK6dZlq
# czKU0RBEEC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs06wXGXuxb
# Grzryc/NrDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e5TXnMcva
# k17cjo+A2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtVgkEy19sE
# cypukQF8IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85tRFYF/ck
# XEaPZPfBaYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+SkjqePdwA
# 5EUlibaaRBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1YxwLEFgqrFj
# GESVGnZifvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzlDlJRR3S+
# Jqy2QXXeeqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFrb7GrhotP
# wtZFX50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATowggE2MA8G
# A1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9PMB8G
# A1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIBhjB5
# BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0
# LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2hjRodHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3Js
# MBEGA1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/Q1xV5zhf
# oKN0Gz22Ftf3v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNKei8ttzjv
# 9P+Aufih9/Jy3iS8UgPITtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHrlnKhSLSZ
# y51PpwYDE3cnRNTnf+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4oVaO7KTV
# Peix3P0c2PR3WlxUjG/voVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5AY8WYIsGy
# WfVVa88nq2x2zm8jLfR+cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNNn3O3Aamf
# V6peKOK5lDGCA3wwggN4AgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRp
# Z2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVT
# dGFtcGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1IENBMQIQCoDvGEuN8QWC0cR2p5V0
# aDANBglghkgBZQMEAgEFAKCB0TAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQw
# HAYJKoZIhvcNAQkFMQ8XDTI1MTExOTAxMTgxMlowKwYLKoZIhvcNAQkQAgwxHDAa
# MBgwFgQU3WIwrIYKLTBr2jixaHlSMAf7QX4wLwYJKoZIhvcNAQkEMSIEIP7Q50O2
# 4kda/5FPxo0yLUSbXad02DA/RuVXanPtr0iVMDcGCyqGSIb3DQEJEAIvMSgwJjAk
# MCIEIEqgP6Is11yExVyTj4KOZ2ucrsqzP+NtJpqjNPFGEQozMA0GCSqGSIb3DQEB
# AQUABIICAAl7Venr4L/9hKWiagyqnAssnbgVc9W6SwHApO0H0ucY8+0vQ56cXgDG
# dkD4bEg6yTIi4Wyv5lKvQbXRtKPe3rM3/4ujndYqyIsJ3vinEIIJPyDrq+iKuMUP
# dxecyJTDGsiuCRlFPGCbTIn/BpA5OR3CTVaZxQUJ+8Wn65n3VsqRzOnPdUDVDO14
# TiCYE+aepisJxwtYlt8mWjEk3ZQtQD7dEH51XqgfmcCvc8Ja4cnVKYUUkowvn+uY
# hZ8tow3WYQNbMWGy96kdAvCnj3WLJD+14OuSJladOMQbVBRVuhHT5K8jy6989yAJ
# HCSampZLiMvNIas7MN6UcjtheOxHvNSsht1f9wGyI3lbNVRC50I0oR6Pg3IIG6Ld
# /8kVVQL5BuKjrF1eqgUqpJW25fUwhi8h5B1BTk720e7Q+JFTTUFaKhB2NkCbEVDz
# 2XNKTrAcV0exLee7CGf6zWUbro4iljdo4VjjvqICz7CRMSZvpzSxVSBX+11TppZh
# q5ogX6YFbwGjCvgNjFe91Piqx3EE3rSMrFMZNV70U0ChvfyYqnsWAR2NGoFKF2W6
# MrizresorwkPUQl8Hsdr8mkfmK4MK9jUNqlmBljHH9C0UQJjYR0tjK4olrMHniaf
# 8WLrhbE596PsHOnNSvg7c87Sw07WHPSaoPsmx+do/2KRzTJQZznI
# SIG # End signature block