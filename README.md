# Marshmallow 

Marshmallow aims to become a fully fledged game development environment. It is a WIP, so expect changes to the API

## Building the samples
1. Make sure the submodules are initialized. `git submodule update --init --recursive`
2. Build the build system `odin build ./build`
3. Build all samples at once using `./build samp.*`. Note: On unix shells, the asterisk gets resolved into file names. You might need to escape it, for example `./build samp.\*`. Alternatively, you can call `./build` with no parameters to see what are the available configurations and build them one at a time, or the only one you need
4. The built samples will be available in the `out/samples` folder
