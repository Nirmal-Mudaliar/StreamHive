# Project Setup Instructions

## Prerequisites

1. **Open PowerShell in Admin Mode**
    - Ensure you have administrative privileges.

2. **Change Directory**
    - Navigate to the root folder of this project.

3. **Run Setup Script**
    - Execute the following command to install Go and Chocolatey:
      ```powershell
      Set-ExecutionPolicy Bypass -Scope Process -Force; .\setup.ps1
      ```
    - The script will automatically handle Chocolatey installation and restart if needed.

## What the Setup Script Installs

The setup script automatically installs:
- Go programming language
- Chocolatey package manager
- Make build tool
- Protocol Buffers compiler (protoc)
- mkcert for local SSL certificates
- Azure CLI with container extensions
- Required Go packages:
    - protoc-gen-go
    - protoc-gen-go-grpc
    - sqlc
    - swag
    - gowsdl

## Manual Steps (if needed)

If the setup script fails, you can manually run:

1. **Tidy Go Modules**
   ```bash
   go mod tidy
   ```

2. **Install Required Tools** (these are included in setup.ps1)
   ```bash
   go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
   go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
   go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
   go install github.com/swaggo/swag/cmd/swag@latest
   go install github.com/hooklift/gowsdl/cmd/gowsdl@latest
   ```

## WSDL Generation

1. **Generate Go Code from WSDL**
   Use the following command to generate Go code from a WSDL file:
   ```bash
   gowsdl -o checkout.service.go -p checkout VX_Ecommerce_APIs.xml
   ```

## Additional Notes

- The setup script handles all dependencies automatically
- Run `.\setup.ps1` once in admin PowerShell and everything will be configured
- For any issues, refer to the documentation or contact the project maintainer