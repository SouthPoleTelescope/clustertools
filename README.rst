Using an installed toolset
--------------------------

If software is installed at /path/to/software (i.e. you are reading this README
at /path/to/software/README), then run the following:

.. code-block:: bash

   eval `/path/to/software/setup.sh`

This will set up your PATH, PYTHONPATH, LD_LIBRARY_PATH, and a few other things
appropriately. To have this occur on login, add the above line to your .profile,
.bash_profile, or .csh_profile, depending on which shell you use.

The setup.sh script will point your environment at the standard toolset, which
is currently py3-v3.

Current defined toolsets:

- py2-v1: Python 2.7.11-based tools (deprecated)
- py3-v1: Python 3.5.2-based tools (deprecated)
- py3-v2: Python 3.6.1-based tools (deprecated)
- py3-v3: Python 3.7.0-based tools (default)
- py3-v4: Python 3.10.1-based tools (latest)
- py3-v5: Python 3.12.3-based tools (dev)

Installing software for the first time
--------------------------------------

If you are just downloading this, make sure the repository is checked out to
the location at which you want to install the software. Then run the buildall.sh
script as follows:

.. code-block:: bash

   /path/to/software/buildall.sh /path/to/some/scratch/directory

The scratch directory is used for temporary files only and will be deleted when
the script completes. It should not be a network filesystem. It usually takes
2-3 hours to finish compiling and installing each toolset.

If you have a heterogeneous cluster with with multiple CPU architectures and/or
operating systems, then run buildall.sh on each of them. The software will be
automaically installed in subdirectories for each system architecture.

