- [How to Create and Publish a Python Package Using Poetry to a Local PyPI Registry](#how-to-create-and-publish-a-python-package-using-poetry-to-a-local-pypi-registry)
  - [Prerequisites](#prerequisites)
  - [Step 1: Create a New Python Package](#step-1-create-a-new-python-package)
  - [Step 2: Add Functionality to the Package](#step-2-add-functionality-to-the-package)
  - [Step 3: Configure Poetry to Use the Local PyPI Registry](#step-3-configure-poetry-to-use-the-local-pypi-registry)
  - [Step 4: Build the Package](#step-4-build-the-package)
  - [Step 5: Publish the Package to the Local PyPI Server](#step-5-publish-the-package-to-the-local-pypi-server)
  - [Step 6: Install the Package from the Local PyPI Server](#step-6-install-the-package-from-the-local-pypi-server)
- [Install packages from your local PyPI registry](#install-packages-from-your-local-pypi-registry)
  - [Step 1: Activate the Virtual Environment](#step-1-activate-the-virtual-environment)
  - [Step 2: Configure `pip` to Use the Local PyPI Registry](#step-2-configure-pip-to-use-the-local-pypi-registry)
  - [Step 3: Install Packages from the Local Registry](#step-3-install-packages-from-the-local-registry)
  - [Optional: Make the Configuration Global](#optional-make-the-configuration-global)

# How to Create and Publish a Python Package Using Poetry to a Local PyPI Registry

This guide walks you through the steps to create a new Python package using Poetry and publish it to a local PyPI registry.

## Prerequisites

- **Python**: Ensure Python is installed on your system.
- **Poetry**: Install Poetry by following the instructions on the [official website](https://python-poetry.org/docs/#installation).
- **Local PyPI Server**: Set up a local PyPI server. You can use the `pypi-server` as shown in the setup script.

## Step 1: Create a New Python Package

1. Open your terminal.
2. Navigate to the directory where you want to create your new package.
3. Run the following command to create a new package:

   ```bash
   poetry new <package_name>
   ```

Replace `<package_name>` with your desired package name. This command creates a new directory with the package structure.

4. Navigate into the package directory:

   ```bash
   cd <package_name>
   ```

## Step 2: Add Functionality to the Package

1. Open the `__init__.py` file located in the `<package_name>/<package_name>` directory.
2. Add your Python code. For example:

   ```python
   def greet():
       return "Hello, world!"
   ```

3. Save the file.

## Step 3: Configure Poetry to Use the Local PyPI Registry

1. Ensure your local PyPI server is running.
2. Run the following command to configure Poetry to use the local PyPI server:

   ```bash
   poetry config repositories.local http://localhost:8080
   ```

## Step 4: Build the Package

1. Build the package using the following command:

   ```bash
   poetry build
   ```

This will create distribution files (`.tar.gz` and `.whl`) in the `dist` directory.

## Step 5: Publish the Package to the Local PyPI Server

1. Publish the package to the local PyPI server with the following command:

   ```bash
   poetry publish --repository local
   ```

The package will be uploaded to the local registry at `http://localhost:8080`.

## Step 6: Install the Package from the Local PyPI Server

1. Ensure your virtual environment is active (e.g., `source $HOME/.virtualenvs/pypiserver/bin/activate`).
2. Install your package using pip:

   ```bash
   pip install <package_name>
   ```

Replace `<package_name>` with the name of your package.

# Install packages from your local PyPI registry

### Step 1: Activate the Virtual Environment

First, activate the virtual environment where you want to install the packages:

source /path/to/your/virtualenv/bin/activate

### Step 2: Configure `pip` to Use the Local PyPI Registry

Next, configure `pip` within this virtual environment to use the local PyPI server:

1. Create or modify the `pip` configuration file inside the virtual environment:

   ```bash
   mkdir -p $VIRTUAL_ENV/pip_conf
   touch $VIRTUAL_ENV/pip_conf/pip.conf
   ```

2. Add the local PyPI server as the default index URL by editing the `pip.conf` file:

   ```bash
   echo "[global]" > $VIRTUAL_ENV/pip_conf/pip.conf
   echo "index-url = http://localhost:8080/simple/" >> $VIRTUAL_ENV/pip_conf/pip.conf
   ```

3. To ensure `pip` reads from this configuration file, you may set the `PIP_CONFIG_FILE` environment variable:

   ```bash
   export PIP_CONFIG_FILE=$VIRTUAL_ENV/pip_conf/pip.conf
   ```

### Step 3: Install Packages from the Local Registry

Now, you can install packages from your local PyPI registry using `pip`:

```bash
pip install <package_name>
```

### Optional: Make the Configuration Global

If you frequently work with multiple virtual environments and want to make the local PyPI server available globally, you can modify the global `pip` configuration:

1. Modify the user-level `pip.conf`:

   ```bash
   mkdir -p ~/.config/pip
   touch ~/.config/pip/pip.conf
   ```

2. Add the local registry as the primary index:

   ```bash
   echo "[global]" > ~/.config/pip/pip.conf
   echo "index-url = http://localhost:8080/simple/" >> ~/.config/pip/pip.conf
   ```

---

[Back to Home](../README.md)
