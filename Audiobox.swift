//
//  Audiobox.swift
//  AudioboxDemo
//
//  Created by Alberto Lourenço on 5/1/20.
//  Copyright © 2020 Alberto Lourenco. All rights reserved.
//

import Foundation
import MediaPlayer
import AVFoundation

//-----------------------------------------------------------------------
//  AudioboxItem
//-----------------------------------------------------------------------

struct AudioboxItem {
    
    var id = UUID()
    
    var url: URL
    var isLocal: Bool
    var cover: UIImage?
    
    var title: String
    var subtitle: String
    var author: String
}

extension AudioboxItem: Equatable {
    static public func ==(first: AudioboxItem, second: AudioboxItem) -> Bool {
        return first.url == second.url
    }
}

//-----------------------------------------------------------------------
//  AudioboxDelegate
//-----------------------------------------------------------------------

protocol AudioboxDelegate {
    
    func playerStopped()
    func playerPaused(audio: AudioboxItem)
    func playerPlaying(audio: AudioboxItem)
}

//-----------------------------------------------------------------------
//  Audiobox
//-----------------------------------------------------------------------

class Audiobox {
    
    //  Configs
    private var queueIndex: Int = 0
    private var timeObserverToken: Any?
    private(set) var isPlaying: Bool = false
    private let controlCenter = MPRemoteCommandCenter.shared()
    
    private var queue: Array<AudioboxItem> = []
    private var delegate: AudioboxDelegate?
    
    //  Player
    
    private var player: AVPlayer?
    private(set) var audioPlaying: AudioboxItem?
    
    init(queue: Array<AudioboxItem>, delegate: AudioboxDelegate) {
        
        // config player
        
        self.queue = queue
        self.delegate = delegate
        
        // play audio with device in silent mode
        
        do {
           try AVAudioSession.sharedInstance().setCategory(.playback)
        }catch{
            print(error.localizedDescription)
        }
        
        // observe when audio ends to continue
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidFinishPlaying),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: nil)
        
        // config control center actions
        
        self.configControlPanel()
    }
    
    private func resetPlayer() {
        
        if let timeToken = timeObserverToken {
            player?.removeTimeObserver(timeToken)
            timeObserverToken = nil
        }
        
        player = nil
    }
    
    private func configControlPanel() {
        
        controlCenter.stopCommand.addTarget { [unowned self] event in
            self.stop()
            return !self.isPlaying ? .success : .commandFailed
        }
        
        controlCenter.playCommand.addTarget { [unowned self] event in
            self.play()
            return self.isPlaying ? .success : .commandFailed
        }
        
        controlCenter.pauseCommand.addTarget { [unowned self] event in
            self.pause()
            return !self.isPlaying ? .success : .commandFailed
        }
        
        controlCenter.nextTrackCommand.addTarget { [unowned self] event in
            self.next()
            return self.isPlaying ? .success : .commandFailed
        }
        
        controlCenter.previousTrackCommand.addTarget { [unowned self] event in
            self.previous()
            return self.isPlaying ? .success : .commandFailed
        }
        
        // other commands
        
        controlCenter.playCommand.isEnabled = true
        controlCenter.pauseCommand.isEnabled = true
        controlCenter.stopCommand.isEnabled = true
        
        controlCenter.seekForwardCommand.isEnabled = false
        controlCenter.seekBackwardCommand.isEnabled = false
        controlCenter.skipForwardCommand.isEnabled = false
        controlCenter.skipBackwardCommand.isEnabled = false
        
        // start receiving remote commands
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    //---------------------------------------
    //  MARK: - Player
    //---------------------------------------
    
    /// Stop current queue item
    func stop() {
        
        isPlaying = false
        audioPlaying = nil
        
        player?.pause()
        player?.seek(to: CMTime(seconds: 0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        
        delegate?.playerStopped()
        
        self.clearLockScreenAlbumInfo()
    }
    
    /// Play queue
    func play() {
        
        if queueIndex >= queue.count { // check position
            return
        }
        
        let audio = queue[queueIndex]
        
        if let playingAudio = audioPlaying, audio == playingAudio { // play paused audio
            
            player?.play()
            
        }else{ // start new audio

            self.resetPlayer()
            
            audioPlaying = audio
            
            let item = AVPlayerItem(url: audio.url)
            
            player = AVPlayer(playerItem: item)
            player?.volume = 1.0
            player?.play()
            
            let timeScale = CMTimeScale(NSEC_PER_SEC)
            let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)
            timeObserverToken = player?.addPeriodicTimeObserver(forInterval: time,
                                                                queue: .main,
                                                                using: { [weak self] time in
                if let audio = self?.audioPlaying {
                    self?.setLockScreenAlbumInfo(audio: audio)
                }
            })
        }
        
        isPlaying = true
        
        delegate?.playerPlaying(audio: audio)
        
        self.updateControlPanel()
        self.setLockScreenAlbumInfo(audio: audio)
    }
    
    /// Pause current item
    func pause() {
        
        isPlaying = false
        
        player?.pause()
        
        guard let audio = audioPlaying else { return }
        delegate?.playerPaused(audio: audio)
    }
    
    /// Play next queue item
    func next() {
        queueIndex += 1 // increase queue position
        
        if queueIndex < queue.count {
            
            self.stop()
            self.play()
            
            guard let audio = audioPlaying else { return }
            delegate?.playerPlaying(audio: audio)
        }else{
            self.reset()
        }
    }
    
    /// Play previous queue item
    func previous() {
        queueIndex -= 1 // decrease queue position
        
        if queueIndex >= 0 {
            
            self.stop()
            self.play()
            
            guard let audio = audioPlaying else { return }
            delegate?.playerPlaying(audio: audio)
        }else{
            self.reset()
        }
    }
    
    //---------------------------------------
    //  MARK: - Queue
    //---------------------------------------
    
    /// Stop queue and move player to the first item
    func reset() {
        
        self.stop()
        self.resetPlayer()
        self.clearLockScreenAlbumInfo()
        
        queueIndex = 0
    }
    
    /// Move an item from position to another
    /// - Parameter index: current position
    /// - Parameter to: new position
    func move(from index: Int, to newIndex: Int) {
        let audio = queue.remove(at: index)
        queue.insert(audio, at: newIndex)
    }
    
    /// Jump to item and play it by passing index
    /// - Parameter index: current position
    func jumpTo(index: Int) {
        if queue.count > 0 && index >= 0 && index < queue.count {
            queueIndex = index
            self.play()
        }
    }
    
    /// Add new item to the queue
    /// - Parameter item: new audio item
    /// - Parameter toPosition: if its not informed, the item will be added at last position
    func add(_ item: AudioboxItem, toPosition position: Int = Int(INT_MAX)) {
        if position != Int(INT_MAX) {
            queue.insert(item, at: position)
        }else{
            queue.append(item)
        }
    }
    
    /// Remove an item from the queue by index
    /// - Parameter index: index to remove item
    func remove(index: Int) {
        if queue.count > 0 && index >= 0 && index < queue.count {
            queue.remove(at: index)
        }
    }
    
    //---------------------------------------
    //  MARK: - Behaviors
    //---------------------------------------
    
    @objc private func playerDidFinishPlaying() {
        self.next()
    }
    
    //---------------------------------------
    //  MARK: - Control Panel
    //---------------------------------------
    
    private func updateControlPanel() {
        
        // next and previous commands
        
        controlCenter.nextTrackCommand.isEnabled = queue.count > 1 && queueIndex < (queue.count - 1)
        controlCenter.previousTrackCommand.isEnabled = queue.count > 1 && queueIndex > 0
        
        // seek bar command
        
        guard let audio = audioPlaying else {
            controlCenter.changePlaybackPositionCommand.isEnabled = false
            return
        }
        
        if audio.isLocal { // its a local audio file

            controlCenter.changePlaybackPositionCommand.isEnabled = true
            controlCenter.changePlaybackPositionCommand.addTarget { (remoteEvent) -> MPRemoteCommandHandlerStatus in
                if let event = remoteEvent as? MPChangePlaybackPositionCommandEvent {
                    self.player?.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: 1))
                    return .success
                }
                return .commandFailed
            }
        }
    }
    
    private func setLockScreenAlbumInfo(audio: AudioboxItem) {
        
        // basic infos
        
        var info: Dictionary<String, Any> = [MPMediaItemPropertyTitle : audio.title,
                                             MPMediaItemPropertyAlbumTitle : audio.subtitle,
                                             MPMediaItemPropertyArtist : audio.author,
                                             MPNowPlayingInfoPropertyIsLiveStream : !audio.isLocal]
        
        // duration & elapsed time
        
        if let duration = player?.currentItem?.asset.duration, let currentTime = player?.currentTime() {
            info[MPNowPlayingInfoPropertyPlaybackRate] = 1
            info[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(duration)
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(currentTime)
        }
        
        // cover
        
        if let image = audio.cover {
            let square = UIScreen.main.bounds.width - 20
            let albumArt = MPMediaItemArtwork(boundsSize: CGSize(width: square, height: square)) { (size) -> UIImage in
                return image
            }
            info[MPMediaItemPropertyArtwork] = albumArt
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    private func clearLockScreenAlbumInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
