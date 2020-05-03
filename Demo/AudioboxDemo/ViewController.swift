//
//  ViewController.swift
//  AudioboxDemo
//
//  Created by Alberto Lourenço on 5/1/20.
//  Copyright © 2020 Alberto Lourenco. All rights reserved.
//

import UIKit

class ViewController: UIViewController, AudioboxDelegate {
    
    var audios: Array<AudioboxItem> {
        get {

            let audio_0 = AudioboxItem(url: Bundle.main.url(forResource: "audio_0", withExtension: "mp3")!,
                                       isLocal: true,
                                       cover: UIImage(named: "cover_0.png"),
                                       title: "Piece Of Your Heart",
                                       subtitle: "Meduza remix of Friendly Fires",
                                       author: "Meduza ft. Goodboys")
            
            let audio_1 = AudioboxItem(url: Bundle.main.url(forResource: "audio_1", withExtension: "mp3")!,
                                       isLocal: true,
                                       cover: UIImage(named: "cover_1.jpg"),
                                       title: "THE SCOTTS",
                                       subtitle: "Astroworld",
                                       author: "Travis Scott ft. Kid Cudi")
            
            return [audio_0, audio_1]
        }
    }
    
    @IBOutlet var imgCover: UIImageView?
    @IBOutlet var lblTitle: UILabel?
    @IBOutlet var lblAuthor: UILabel?
    @IBOutlet var btnPlay: UIButton?
    @IBOutlet var btnNext: UIButton?
    @IBOutlet var btnPrevious: UIButton?
    
    //-----------------------------------------------------------------------
    //  MARK: - UIViewController
    //-----------------------------------------------------------------------
    
    var player: Audiobox!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        player = Audiobox(queue: audios, delegate: self)
    }
    
    //-----------------------------------------------------------------------
    //  MARK: - Audiobox Delegate
    //-----------------------------------------------------------------------

    func playerStopped() {

    }

    func playerPaused(audio: AudioboxItem) {
        self.btnPlay?.setBackgroundImage(UIImage(systemName: "play.circle"), for: .normal)
    }

    func playerPlaying(audio: AudioboxItem) {
        
        self.imgCover?.image = audio.cover
        
        self.lblTitle?.text = audio.title
        self.lblAuthor?.text = audio.author
        
        self.btnNext?.isEnabled = audios.last != audio
        self.btnPrevious?.isEnabled = audios.first != audio
        
        self.btnPlay?.setBackgroundImage(UIImage(systemName: "pause.circle"), for: .normal)
    }
    
    //-----------------------------------------------------------------------
    //  MARK: - View Player
    //-----------------------------------------------------------------------
    
    @IBAction func playPause() {
        player.isPlaying ? player.pause() : player.play()
    }
    
    @IBAction func next() {
        player.next()
    }
    
    @IBAction func previous() {
        player.previous()
    }
}
