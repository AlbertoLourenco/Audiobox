![cover](https://raw.githubusercontent.com/AlbertoLourenco/Audiobox/master/github-assets/cover.png)

AudioBox is a class that can help you implement audio players.

Just create the audio queue you want to play and later, if necessary, you can change the source, insert more audios, remove, skip or go back tracks, and you can also control it through the notification center.

*The UI in this project is only to test some features.

## How to use

First you need to create some `AudioboxItem` objects like that:

```swift
AudioboxItem(url: Bundle.main.url(forResource: "audio_1", withExtension: "mp3")!,
                                  isLocal: true,
                                  cover: UIImage(named: "cover_1.jpg"),
                                  title: "THE SCOTTS",
                                  subtitle: "Astroworld",
                                  author: "Travis Scott ft. Kid Cudi")
```

After that, you can instantiate the `AudioBox` adding the array with created audio objects.

```swift
let player = Audiobox(queue: audios, delegate: self)
```

## AudioboxDelegate

```swift
func playerStopped()
func playerPaused(audio: AudioboxItem)
func playerPlaying(audio: AudioboxItem)
```

## Call actions

AudioBox has some functions that you can call to control your audio queue.

```swift
// Stop current queue item
func stop()

// Play queue
func play()

// Pause current item
func pause()

// Play next queue item
func next()

// Play previous queue item
func previous()

// Stop queue and move player to the first item
func reset()

// Move an item from position to another
func move(from index: Int, to newIndex: Int)

// Jump to item and play it by passing index
func jumpTo(index: Int)

// Add new item to the queue
func add(_ item: AudioboxItem, toPosition position: Int = Int(INT_MAX))

// Remove an item from the queue by index
func remove(index: Int)
```

## Requirements

```
- iOS 13+
- Xcode 13
- Swift 5
```

## This project uses:

```
- UIKit
- MediaPlayer
- AVFoundation
```

## In action

![cover](https://raw.githubusercontent.com/AlbertoLourenco/Audiobox/master/github-assets/preview-1.gif)
