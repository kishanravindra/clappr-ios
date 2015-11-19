import Quick
import Nimble
import Clappr

class MediaControlTests: QuickSpec {
    
    override func spec() {
        describe("MediaControl") {
            let sourceUrl = NSURL(string: "http://globo.com/video.mp4")!
            var container: Container!
            var playback: StubedPlayback!
            
            beforeEach() {
                playback = StubedPlayback(url: sourceUrl)
                container = Container(playback: playback)
            }
            
            context("Initialization") {
                
                it("Should have a init method that receives a container") {
                    let mediaControl = MediaControl.initWithContainer(container)
                    
                    expect(mediaControl).toNot(beNil())
                    expect(mediaControl.container) == container
                }
            }
            
            context("Behavior") {
                var mediaControl: MediaControl!
                
                beforeEach() {
                    mediaControl = MediaControl.initWithContainer(container)
                }
                
                context("Visibility") {
                    it("Should start with controls visible") {
                        expect(mediaControl.playPauseButton.hidden).to(beFalse())
                        expect(mediaControl.controlsOverlayView.hidden).to(beFalse())
                        expect(mediaControl.controlsWrapperView.hidden).to(beFalse())
                    }
                    
                    it("Should hide it's control after hide is called") {
                        mediaControl.hide()
                        
                        expect(mediaControl.playPauseButton.hidden).to(beTrue())
                        expect(mediaControl.controlsOverlayView.hidden).to(beTrue())
                        expect(mediaControl.controlsWrapperView.hidden).to(beTrue())
                    }
                    
                    it("Should show it's control after show is called") {
                        mediaControl.hide()
                        mediaControl.show()
                        
                        expect(mediaControl.playPauseButton.hidden).to(beFalse())
                        expect(mediaControl.controlsOverlayView.hidden).to(beFalse())
                        expect(mediaControl.controlsWrapperView.hidden).to(beFalse())
                    }
                }
                
                context("Play") {
                    it("Should call container play when is paused") {
                        playback.playing = false
                        mediaControl.playPauseButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                        expect(container.isPlaying).to(beTrue())
                    }
                    
                    it("Should change button state to selected") {
                        mediaControl.playPauseButton.selected = false
                        mediaControl.playPauseButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                        expect(mediaControl.playPauseButton.selected).to(beTrue())
                    }
                    
                    it("Should trigger playing event ") {
                        var callbackWasCalled = false
                        mediaControl.once(MediaControlEvent.Playing.rawValue) { _ in
                            callbackWasCalled = true
                        }
                        
                        mediaControl.playPauseButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                        
                        expect(callbackWasCalled).to(beTrue())
                    }
                }
                
                context("Pause") {
                    beforeEach() {
                        playback.playing = true
                    }
                    
                    it("Should call container pause when is playing") {
                        mediaControl.playPauseButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                        expect(container.isPlaying).to(beFalse())
                    }
                    
                    it("Should change button state to not selected") {
                        mediaControl.playPauseButton.selected = true
                        mediaControl.playPauseButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                        expect(mediaControl.playPauseButton.selected).to(beFalse())
                    }
                    
                    it("Should trigger not playing event ") {
                        var callbackWasCalled = false
                        mediaControl.once(MediaControlEvent.NotPlaying.rawValue) { _ in
                            callbackWasCalled = true
                        }
                        
                        mediaControl.playPauseButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                        
                        expect(callbackWasCalled).to(beTrue())
                    }
                }
                
                context("Current Time") {
                    it("Should start with 00:00 as current time") {
                        expect(mediaControl.currentTimeLabel.text) == "00:00"
                    }
                    
                    it ("Should listen to current time updates") {
                        let info: EventUserInfo = ["position" : 78]
                        playback.trigger(PlaybackEvent.TimeUpdated.rawValue, userInfo: info)
                        
                        expect(mediaControl.currentTimeLabel.text) == "01:18"
                    }
                }
                
                context("Duration") {
                    it("Should start with 00:00 as duration") {
                        expect(mediaControl.currentTimeLabel.text) == "00:00"
                    }
                    
                    it ("Should listen to Ready event ") {
                        playback.trigger(PlaybackEvent.Ready.rawValue)
                        
                        expect(mediaControl.durationLabel.text) == "00:30"
                    }
                }
            }
        }
    }
    
    class StubedPlayback: Playback {
        var playing = false
        
        override func isPlaying() -> Bool {
            return playing
        }
        
        override func play() {
            playing = true
        }
        
        override func pause() {
            playing = false
        }
        
        override func duration() -> Double {
            return 30
        }
    }
}