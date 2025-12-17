# Documentation

# Index

- [Getting Started](#getting-started)
  - [Windows](#windows)
  - [Linux](#linux)
  - [macos](#macos)
- [Interface](#interface)
  - [Basic UI information](#basic-ui-information)
  - [Assets](#assets)
  - [Basic movement concepts](#basic-movement-concepts)
  - [Wiggle Appendages](#wiggle-appendages)
  - [Settings](#settings)
  - [Assigning Input keys](#assigning-input-keys)
  - [Save and Load](#save-and-load)
  - [Layout mode](#layout-mode) (Still Work in progress, not recommended to use)
- [FAQ](#faq)

## Getting Started

Download the latest Version of PNGTuber-Remix  
[Download](https://github.com/MudkipWorld/PNGTuber-Remix/releases/latest)

### Windows

make sure you **downloaded** and **extracted** the correct zip archive  
> **not** the  Source code (zip|tar.gz) 

```
📂 PNGTubeRemix(Windows)
 ┣📄 DefaultTraining.tres
 ┣📄 GlobalInput.windows.template_release.x86_64.dll
 ┣📄 PNGTube Remix.console.exe
 ┣📄 PNGTube Remix.exe
 ┣📄 PNGTube Remix.pck
 ┣📄 WebsocketDocumentation.txt
 ┣📄 godotgif.windows.template_release.x86_64.dll
 ┣📄 libgcc_s_seh-1.dll
 ┣📄 libstdc++-6.dll
 ┣📄 libuiohook.dll
 ┗📄 libwinpthread-1.dll
```
just run the `PNGTube Remix.exe` file

### Linux

make sure you **downloaded** and **extracted** the correct zip archive  
> **not** the  Source code (zip|tar.gz) 

```
📂 PNGTubeRemix(Linux)
 ┣📄 GlobalInput.linux.template_release.x86_64.so
 ┣📄 PNGTube-Remix.pck
 ┣📄 PNGTube-Remix.sh
 ┣📄 PNGTube-Remix.x86_64
 ┣📄 libgodotgif.linux.template_release.x86_64.so
 ┗📄 libuiohook.so
```
then make the files executable
`chmod +x PNGTube-Remix.sh PNGTube-Remix.x86_64`
just run the `PNGTube-Remix.sh` file

### macOS

Due to macOS restrictions and code signing requirements, there is currently **no prebuilt release** available.  
Official support for macOS has therefore been discontinued.  

If macOS is still required, the application might can be built **manually from source** using the Godot engine.  
This is intended for advanced users who are comfortable compiling and troubleshooting on macOS.  

Things to keep in mind:  
- No ready to run downloads are provided  
- No guarantees for stability or compatibility  
- No official support or updates for this platform  

If that sounds acceptable, building it yourself is the only option.  
If not… well, other platforms exist.  

## Interface
### Basic UI information
#### Right Panel : 
##### Properties : 
- Color : Modulate/ Tints the object.  
- Blend : Blend-Modes like Add, Multiply, etc  
- Z-Order : The order of the sprite, think of it like  
  Changing the layer of your drawings, but it is way  
  more free since it doesn’t fully depends on what  
  object it is connected/ linked to.  
- Pos-x, y and Rotation : You can manually change  
  the position and rotation from these.  
- Offset : Change the sprite’s rotation point.  
- Size-x, y : Changes the size of the object.  
- Visible : Changes the main visibility of the object.

Now here is where things get interesting!

- Is Eyes toggle and is Open:
  if the Toggle is true, the object would be considered to be a part  
  of the eyes. Checking Eye Open means the current selected  
  object is/are open eyes, if unchecked, it means closed eyes.  
- Is Mouth and is Open:  
  Same thing as the Eyes toggle, but for the mouth.  

You could always experiment with them. Despite thing software mainly  
focusing on rigging, this doesn’t mean you can’t make simple PNGTuber  
models like the ones seen in VeadoTube Mini and Gazō-Tuber  
(Links if you are curious, feel free to check them out too VeadoTube , Gazō  Tube).  


- Ignore Bounce:  
  Ignores Global bounce. Let’s say your sprite squishes, but you don’t want it to squish even more when the model bounces. You simply toggle this to prevent that from happening. Td;lr the part(s) don’t get affected if the model is bouncing, etc..
- Physics:  
If this is on, the object’s movement gets affected by the parent’s Y-axis movement. This could be used to add more flavor to your model!

#### Ignore Bounce Example:
|Ignore Bounce On|Ignore Bounce Off|
| --- | --- |
|PicA|PicB|

#### Physics Example:
|Physics On|Physics Off|
| --- | --- |
|PicA|PicB|

#### Clip Children:
Sadly I am unable to find a good way to implement Clipping Masks.  
The only current way to clip stuff is to make the object a child of  
what you want to clip the object to and enable Clip Children on  
the parent object.  
This is a limitation I hope to be able to solve in the future 😇 

### Assets
So! You want to have assets, like glasses, hats, etc.. don’t you?

Okay, so here are some very basic info to begin with. Any object (Sprite or Wiggly Appendage) can be considered an asset, animated or not!

Is a Toggle Asset : This is the main toggle that identifies if the object you selected should be considered an Asset or a normal object.

Should Disappear On Other Assets Toggle : Quite the mouthful, but this is important. You may want some assets to disappear when others appear and vice versa. Let’s say you have two types of glasses, normal and sunglasses. You want to toggle between them, in the panel under the toggle, you add the key that the other asset uses to be toggled on and off to have the current one disappears.


### Basic movement concepts
### Wiggle Appendages
### Settings
### Assigning Input keys
### Save and Load
### Layout mode
(Still Work in progress, not recommended to use)


## FAQ

- I don’t know how to use this with OBS!  
  Open your model under FIles > Open  
  Set BG Color at the Top Bar to Transparent  
  Set Mode at the Top Bar to PNGTube  
  Add Game Capture in OBS  
  Allow transparency in Game Capture options  
  Capture PNGTube Remix  

- My mic doesn’t seem to be picking up no matter what I do?  
  This is a problem with Godot and picking up microphones with more than  
  two channels, not sure what can be done outside of maybe faking a 2  
  channel mic with an application like Voicemeeter Banana.  

- I’m trying to set up Advanced Lip Sync and there is only one phoneme…  
  In the lip sync config tab, go to Files > New File in the top right corner  
  and then Files > Save to save it over the broken default one.  

- I opened up an image/model and there’s a giant black square!  
  Remix seems to have different limits for image sizes depending on your   
  computer, this is especially apparent for giant image files like if you  
  didn’t crop the empty space from your sprite sheets. Keep this in mind when  
  creating a model for another person.  

- I can’t seem to use hotkeys on Linux when Remix isn’t focused! (Steam Deck runs on Linux)  
  Wayland (The protocol used for handling stuff like hotkeys on Linux)  
  doesn’t currently allow for global inputs without some editing due to  
  security reasons (or it might just not work at all.)  
  You can try enabling Legacy X11 App Support or launching the program with Xwayland.  

- My mouth isn’t opening and closing properly! (Includes Advanced Lip Sync)  
  Most commonly this is a problem with the audio settings you have,  
  make sure you have the mic you’d like to use selected and fiddle with  
  the volume sensitivity and threshold inside of the volume bar until you have the desired effect.  

- Clipping isn’t working properly!  
  Clipping is done through objects that are parent-child and  
  the child MUST have Z-order value of 0 (It’s near the top of the properties tab.)  
  Remember that the last object attached to the parent will appear in front of the others.  
  You also can’t clip something to a clipped object.  

- I can’t unparent an object!  
  Drag it to the model folder at the top of the sprite list.  

- My sprite sheet frames are cutting into each other!  
  To function as spritesheets, each frame of your animation must  
  have the same amount of space allocated to it. Otherwise the  
  frames will cut into each other! Use frames of uniform size and  
  if you must, use an online texture packer.  

- How do I record sounds for Advanced Lip Sync?  
  Add a new recording slot with the Plus symbol.  
  Then press and release the mic icon, it will record  
  for a split second after it is released.  
  Make sure you only record the viseme and not the  
  surrounding parts of the example words,  
  some sounds will be hard but just do your best.  

- How big should I make my images for the model?  
  Try to think of the scale you’ll be using your model in,  
  no point in making a 4k model if you’re only streaming in 720p.  
  Try not to go overboard either or you can run into issues with performance  
  or if they’re really big, the black box glitch. If you’re still struggling to decide  
  a canvas size of around 1000-2000 px is a decent place to start.  
