# source-engine-css-enhancer-modules

**Modules need to be compiled into .pyd files using Cython.**
**Command line to compile: py build.py build_ext --inplace**
**Example code to build the module:**

```python
from setuptools import setup
from Cython.Build import cythonize

setup(
    name="spray_checker",
    ext_modules=cythonize(
        "spray_checker.pyx",
        language_level=3,
    ),
)

```
