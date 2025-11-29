# Contributing to n8n Localtunnel Setup

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:
1. Check if the issue already exists
2. Create a new issue with:
   - Clear description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Environment details (OS, Node version, etc.)

### Submitting Changes

1. **Fork the repository**
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test your changes**:
   - Test the script on your system
   - Ensure it works with different configurations
5. **Commit your changes**:
   ```bash
   git commit -m "Add: description of your changes"
   ```
6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Create a Pull Request**

## Code Style

- Follow existing code style
- Use meaningful variable names
- Add comments for complex logic
- Keep functions focused and small

## Testing

Before submitting:
- Test on macOS and Linux if possible
- Verify Docker and Node.js requirements
- Test tunnel creation and reconnection
- Ensure error handling works correctly

## Questions?

Feel free to open an issue for questions or discussions!

