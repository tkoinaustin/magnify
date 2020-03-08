# Magnify

## About the App
My wife suggested a magnifying glass application, expressing concerns that although she has dozens of pairs of "Readers" laying around the house, they were never there when she needed them. 

I asked her to look at the currently available apps in the App Store to see what she liked and disliked about them. We came up with a design together that included simple operation with a minimal number of controls and maximum screen usage. 

Use pinch to zoom the camera, swipe left and right to adjust the light, and simply tap the screen to take a snap shot. Reset sets the zoom back to 1 and turns off the light. Once a picture is taken you can still zoom in on the captured image. When you are done with the picture, tap Clear to go back into camera mode for another picture.

This is a work in progress that will probably end up in the app store after I hire a graphics artist for icons and onboarding images.

## Dependencies
They are pretty much a fact of life, but I try to keep them to a minumum. For this project I use PromiseKit. Actually, I use PromiseKit for most of my projects. I use Carthage as my dependency manager. I used to use Cocoapods, but found Carthage to be a better fit for me. I have the carthage build files included so you don't need to carthage update --platform ios, unless you want too.