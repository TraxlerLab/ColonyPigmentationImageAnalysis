# ColonyPigmentationImageAnalysis

This project contains 2 elements:
- A Swift package with reusable functionality to analyze bacterial colony microscope images. Highlights:
    - [ColonyMasking.swift](Sources/ColonyPigmentationAnalysisKit/ColonyMasking.swift): Implementation of algorithms to differentiate the foreground (colony) from the background (agar plate) and create a mask.
    - [ColonyPigmentation.swift](Sources/ColonyPigmentationAnalysisKit/ColonyPigmentation.swift): Algorithms to calculate the level of pigmentation of a pixel in a colony image consider similarity to a specified key color, and outputting averages across an image.
    - [ColonyMeasurements.swift](Sources/ColonyPigmentationAnalysisKit/ColonyMeasurements.swift): Utility to calculate the size of a colony in square micrometers given a micrometers-per-pixel scale.
- A command-line executable program that takes many parameters that allow you to use the functionality in the Swift package. Some highlights of that are:
    - Masking colonies by removing the background (which allows you to perform analysis on the pixels inside the area of interest: the colony itself)
    - Calculating pigmentation across a colony by comparing its colors against a provided pigmentation key color using the CIE-76 algorithm.

    Currently, this program runs the whole pipeline of analysis for all the images provided, and outputs them in the specified directory. However, it could easily be modified (the implementation of the program all lives in [main.swift](Sources/ColonyPigmentationAnalysis/main.swift))

## Installation
This repository doesn't yet include a compiled version of this program. 
To execute the program, you need to do 3 things:

- Clone this repository: 
```bash
git clone git@github.com:TraxlerLab/ColonyPigmentationImageAnalysis.git
cd ColonyPigmentationImageAnalysis
```

- `swift` needs to be available somewhere in the `$PATH` (Accomplishing this requires different steps depending on the operating system, see below)
- Once Swift is available, you can use the provided [`run`](run) executable Bash script that allows compiling the program and running it in one go:

```bash
./run --help

OVERVIEW: A command line interface to ColonyPigmentationAnalysisKit which implements a pipeline of actions on the images passed in the --images parameter.

See README.md in the repository for more information

USAGE: ./run <options>

OPTIONS:
  --images <images>       Paths to the jpg images to analyze. Use a wildcard to pass many images. Example: 'images/*.jpg'
  --output-path <output-path>
                          Path to a directory where the results will be saved (default: output/)
  --detailed-progress/--no-detailed-progress
                          Whether to print step by step information of the progress (default: false)
  --downscale-factor <downscale-factor>
                          A value between 0 and 1 that will be multiplied by the width and height of each image to downscale them before processing.
                          Use this if processing the images is too slow on your machine, although it will produce less precise results. (default: 1.0)
  --background-chroma-key-color <background-chroma-key-color>
                          An RGB color to compare pixels against to separate colonies from the background (default: #33393E)
  --background-chroma-key-threshold <background-chroma-key-threshold>
                          A value between 0 and 1 that represents how sensitive the background removal is. A higher value means the pixels must be more different from the
                          background to be considered foreground. A lower value means colors more different from `background-chrome-key-color` will still be considered background.
                          (default: 0.15)
  --pigmentation-color <pigmentation-color>
                          An RGB color to compare pixels against when looking for pigmentation (default: #803D33)
  --baseline-pigmentation <baseline-pigmentation>
                          A minimum level of pigmentation that is considered 'background noise' and is subtracted from all values (default: 0.436)
  --pigmentation-histogram-sample-count <pigmentation-histogram-sample-count>
                          Output the pigmentation histogram csv by interpolating to this many values (default: 200)
  --pigmentation-roi-height <pigmentation-roi-height>
                          A value between 0 and 1 to reduce the height of the area considered to calculate pigmentation (default: 0.2)
  --parallelize/--no-parallelize
                          Whether to utilize as many cores as possible to analyze images in parallel (default: true)
  --version               Show the version.
  -h, --help              Show help information.
```

### macOS
- The easiest way to install Swift is to download [Xcode](https://apps.apple.com/us/app/xcode/id497799835?mt=12) from the Mac AppStore (Xcode 11.4 or above is recommended, which requires macOS 10.15 Catalina, but an older version of Xcode 11 should work, although is not officially supported)
- Once downloaded, open it and allow it to install its developer tools.
- After that, you need to make sure the right path to Xcode is set with the `xcode-select` program. To do so, run this in a terminal:

```bash
sudo xcode-select -s /Applications/Xcode.app
```

### Linux
Any Linux distribution officially supported by [Swift](https://swift.org) will work. The instructions here will focus on Ubuntu 18.04 LTS

- Download a Swift release from the [Swift.org downloads page](https://swift.org/download/). Example:

```bash
curl https://swift.org/builds/swift-5.2.4-release/ubuntu1804/swift-5.2.4-RELEASE/swift-5.2.4-RELEASE-ubuntu18.04.tar.gz -o swift5.2.4.tar.gz
```
- Extract the contents of the file:

```bash
tar -xvf swift5.2.4.tar.gz
```

- Place the folder where you'd like to install Swift (the location doesn't matter, as long as it stays there). For the next steps, we'll pretend this location is `~/swift-5.2.4-RELEASE-ubuntu18.04`:

```bash
cp -R swift-5.2.4-RELEASE-ubuntu18.04 ~/swift-5.2.4-RELEASE-ubuntu18.04
```

- Add that location to the `$PATH` variable. The easiest way is by modifying the `~/.bashrc` file. Example:

```bash
echo "export PATH=\"${PATH}:$HOME/swift-5.2.4-RELEASE-ubuntu18.04/usr/bin\"" >> ~/.bashrc
```

### Windows
Swift is not currently well supported on Linux. This will change soon. In the mean time, consider installing an Ubuntu virtual machine and following the Linux instructions above.

## Development
You can edit the sources in any code editor, and then test either run the unit tests with `swift test --enable-test-discovery`, or use the `.run` executable which will compile from source and then run the code.

In macOS, you can use Xcode to edit the sources.
First, run the following command:

```bash
swift package generate-xcodeproj
```

Then open the Xcode project (`ColonyPigmentationAnalysis.xcodeproj`) to work on the code inside of an IDE or debug it with LLDB.
Note: when you run the program from Xcode, it's compiled without optimizations (to allow for debugging). This makes the program significantly slower compared to running with `./run`, as it's very sensitive to these optimizations.

## Implementation details
This project is implemented using Swift 5.2
It utilizes the [swim](https://github.com/t-ae/swim) library to read and write image files (jpg, png...)
Rather than using that library's data types, we implemented the following data types to represent images:

  - [PixelMap](Sources/ColonyPigmentationAnalysisKit/Types.swift): This is a protocol (aka Interface in other languages like Java) which represents the abstract notion of a 2D grid of pixels. The type of pixel can be different for different `PixelMap`: `ImageMap` has `RGBColor` pixels, whereas `MaskBitMap`'s pixels are `MaskBitMap.Pixel`, which are just either `.black` or `.white` values.
  This allows us implement certain operations for both kinds of pixel maps.
  - [Coordinate](Sources/ColonyPigmentationAnalysisKit/Types.swift): A pair of `x` and `y` values representing a 2D point in a `PixelMap`.
  - [PixelSize](Sources/ColonyPigmentationAnalysisKit/Types.swift): The `width` and `height` of a `PixelMap`.
  - [Rect](Sources/ColonyPigmentationAnalysisKit/Types.swift): A rectangle represented by its `size` (`PixelSize`) and its `origin` in the coordinate space of an image (`Coordinate`).
  - [RGBColor](Sources/ColonyPigmentationAnalysisKit/Colors.swift): A red, green, blue representation of a pixel color. 
  - [XYZColor](Sources/ColonyPigmentationAnalysisKit/Colors.swift): A XYZ representation of a color. Used to convert the color to the LAB space (see below).
- [LABColor](Sources/ColonyPigmentationAnalysisKit/Colors.swift): A LAB representation of a color, which we use to calculate more accurate color distances.

 These types give us an abstraction on top of which to implement the following higher level algorithms:

 - Masking:
  [ColonyMasking.swift](Sources/ColonyPigmentationAnalysisKit/ColonyMasking.swift) implements `func maskColony`, which does the following:
    - Convert the source `ImageMap` (RGB grid of pixels) to a `MaskBitMap` (grid of binary black/white pixels).
    - For every pixel in the original `ImageMap`, the resulting pixel in the `MaskBitMap` is:
      - `.white` if its considered to be part of the foreground, because its distance to `backgroundKeyColor` is larger than `colorThreshold`.
      - `.black` in the opposite case.
    - `func removeSmallShapeGroups()` cleans up the image by removing small groups of pixels that are left behind that are either white or black. These are considered to be noise.

## Continuous Integration
`.github/workflows/tests.yml` contains a Github action for unit tests to be run when commits are pushed. However, this doesn't work at the moment because there's now way for a [SwiftPackageManager](https://github.com/apple/swift-package-manager) (SPM) package to include assets that can be red from the tests. This will be possible in around June when Swift 5.3 is released.
