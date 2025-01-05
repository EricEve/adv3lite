# ADV3LITE
## What is adv3Lite?
Adv3Lite is an alternative library for use with with the [TADS 3](https://www.tads.org) Interactive Fiction authoring system.
The _library_ is the part of the system that provides the parser (the bit that interprets and executes player commands) and the world model, as opposed to the TADS 3 _language_, which provides a substantial set of intrinsic functions in addition to the set of constructs normally found in a computer language.

Adv3Lite aims to provide a library that's easier to use than the adv3 library which comes standard with TADS 3, but which is almost as powerful and expressive. Adv3Lite misses out the bits that most games don't really need (like postures, room parts, and multiple light levels) while adding in some other bits that are often more useful (like scenes and regions, "borrowed" from Inform 7). Adv3Lite also cuts down drastically on the complexity of the adv3 class hierarchy (there are lots of classes to learn about in adv3!) while maintaining much of their functionality.

One area adv3Lite absolutely doesn't skimp on is the conversation system, which does everything the adv3 one can and more. At the basic level it's very similar to adv3's, but for more advanced conversational work it's more flexible and can do quite a few things that adv3's can't.

In sum, adv3Lite is an alternative library that's easier to learn and easier to use that adv3, but doesn't compromise on the functionality most commonly needed to write interactive fiction. It exists entirely in source form (written in TADS 3, a C-like language designed for writing Interactive Fiction) for use by game authors.

For more detailed information, please refer to the [online documentation](https://faroutscience.com/adv3lite_docs/index.htm) and/or the [Wiki](../../../wiki) assaociated with this site.

## What is in this repository?
This GitHub repository contains all the source files (.t, .tl and .h) files that make up the adv3Lite library along with most of the documentation files (a mix of htm and pdf files, which are located under the docs directory) which explain how to use adv3Lite. It does not yet, however, contain the _adv3 Library Reference Manual_ on account of its large size (the _adv3 Library Reference Manual_ is generated from the adveLite source files by a program called docgen, which also has a GitHub repository on this site). 

The adv3Lite library files contained in this repository are those at the current state of development, which are likely to be ahead of the current release version. The current release version, version 1.6.2, can be found in a zip file [here]([https://github.com/EricEve/adv3lite/releases/download/v.1.6.2/adv3Lite16-2.zip)](https://github.com/EricEve/adv3lite/releases/download/v2.1.1/adv3Lite.2-1-1.zip).  This contains the complete _Library Reference Manual_ alomg with all the other adv3Lite documentation.

## How is adv3Lite used?
It would normally be installed under the extensions directory of your TADS 3 user files. Instructions for using it in a TADS 3 project are provided in the [adv3Lite documentation](https://github.com/EricEve/adv3lite/wiki/Learning-adv3Lite). 

## Licensing Information
Adv3Lite Library Copyright © 2022 Eric Eve
Based in part on the TADS 3 (adv3) and Mercury Libraries © 1997, 2012 by Michael J. Roberts.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For the avoidance of doubt, the Author makes the further grant that users of the adv3Lite library may make unlimited use of story files produced by the adv3Lite library.
