# PhDCaseStudies
Implementation of the case studies found in the PhD thesis entitled "Leveraging Decomposition for Designing, Implementing and Verifying Complex Dependable Real-Time Systems."

## Overview

Within this swift package, you will find the implementation for the case studies with software that generates the corresponding Kripke structures. Within the *Sources* directory, you will find the implementation of each case study. The *Tests* folder contains the software that generates the Kripke structure for each case study respectively. Note that this swift package depends on [swiftfsm](https://github.com/mipalgu/swiftfsm) that contains the framework for creating Logic-Labelled Finite State Machines, and generating Kripke structures. The swiftfsm framework has many other dependencies that you may also wish to look at, each of wich can be viewed by inspecting the corresponding Package.swift file. For example, swiftfsm depends on the [KripkeStructures](https://github.com/mipalgu/KripkeStructures) framework for generating the Kripke structures.

## Prerequisites

To generate the Kripke structures, you must first have a swift version installed that is greater than or equal to swift version 5.8. You may find installation instructions in [swift.org](https://swift.org).

## Building

To build the package, simply run *swift build*:

```bash
$ swift build
```

## Generating Kripke Structures

You may execute the following command to list the available tests that generate specific Kripke structures:

```bash
$ swift test -l
SonarTests.SonarTests/test_combined
SonarTests.SonarTests/test_parallel
SonarTests.SonarTests/test_separate
InitialOneMinuteMicrowaveTests.InitialOneMinuteMicrowaveTests/test_combined
InitialOneMinuteMicrowaveTests.InitialOneMinuteMicrowaveTests/test_separate
BoundedWaitTests.BoundedWaitTests/test_generate
ParameterisedSonarTests.ParameterisedSonarTests/test_separate
FinalOneMinuteMicrowaveTests.FinalOneMinuteMicrowaveTests/test_parallel
FinalOneMinuteMicrowaveTests.FinalOneMinuteMicrowaveTests/test_separate
OnDemandSonarTests.OnDemandSonarTests/test_separate
TimerActuatorMicrowaveTests.TimerActuatorMicrowaveTests/test_separate
```

When you wish to generate a specific Kripke strucutre, then you may do so using a filter:

```bash
$ swift test --filter SonarTests.SonarTests/test_separate
```

This will create a *kripke_structures* directory containing sqlite, graphviz, and nuXmv files for the selected Kripke structure.
