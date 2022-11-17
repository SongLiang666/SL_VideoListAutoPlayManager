//
//  SLVideoListAutoPlayManager.swift
//  SL_VideoListAutoPlayManager
//
//  Created by 宋亮 on 2022/11/16.
//

import Foundation
import AVKit

protocol VideoPlayable: UIView {
    ///播放器容器
    var viewToContainVideo: UIView {get}
    ///设置播放url
    var urlToPlay: URL? {get}
    ///播放状态改变
    func videoStatusChanged(changeTo isPlaying: Bool)
    ///播放时间改变
    func videoPlayTimeChanged(changeTo playTime: Float64)
}

protocol VideoListPlayable: UIScrollView {
    var visibleViews: [VideoPlayable] {get}
}

extension UITableView: VideoListPlayable {
    var visibleViews: [VideoPlayable] {
        let views: [VideoPlayable] = visibleCells.compactMap({ $0 as? VideoPlayable })
        return views
    }
}

extension UICollectionView: VideoListPlayable {
    var visibleViews: [VideoPlayable] {
        let views: [VideoPlayable] = visibleCells.compactMap({ $0 as? VideoPlayable })
        return views
    }
}

class GXRCWVideoListAutoPlayManager {
    
    static let shared = GXRCWVideoListAutoPlayManager()
    
    private var playerVC: AVPlayerViewController = AVPlayerViewController()
    private var preOffsetY: CGFloat = 0
    private var currentPlayingView: VideoPlayable?
    
    private init() {
        playerVC.player = AVPlayer()
        playerVC.view.backgroundColor = .clear
        
        //暂停播放器
//        _ = NotificationCenter.default.rx
//            .notification(Notification.Name(NotificationNameInfo.kPuseVideoPlayer))
////            .take(until: self.rx.deallocated)
//            .subscribe(onNext: { _ in
//                self.playerVC.player?.pause()
//            })
    }
    
    func scrollViewDidScroll(_ scrollView: VideoListPlayable) {

        let currentOffsetY = scrollView.contentOffset.y
        
        //设置播放范围
        let minY = scrollView.frame.height * 0.2
        let maxY = scrollView.frame.height * 0.75
        
        // 获取在 scrollView 自动播放区域内的视频
        let autoPlayableViews = scrollView.visibleViews.filter { view in
            guard let relativeRect = relativeRect(view: view.viewToContainVideo, relativeTo: scrollView), view.urlToPlay != nil else {return false}
            let containerCenterY = relativeRect.minY + relativeRect.height / 2
            return (containerCenterY > minY && containerCenterY < maxY)
        }
        
        guard let first = autoPlayableViews.first else {
            // 没有需要自动播放的视频
            // 移除当前正在离开/已经离开屏幕的视频
            removeCurrentVideoIfLeavingScreen(scrollView: scrollView)
            preOffsetY = currentOffsetY
            return
        }

        // 取出需要自动播放的视频
        let viewToPlay: VideoPlayable = autoPlayableViews.reduce(first) { (result, view) in
            let isScrollToUpper = currentOffsetY < preOffsetY
            return result.frame.maxY > view.frame.maxY ? (isScrollToUpper ? view : result) : (isScrollToUpper ? result : view)
        }
        
        if let currentPlayingView = currentPlayingView, viewToPlay as UIView == currentPlayingView {
            // 满足条件的视频正在播放中
            preOffsetY = currentOffsetY
            return
        }
        removeCurrentVideo(on: scrollView)
        addPlayerView(to: viewToPlay, on: scrollView)
        preOffsetY = currentOffsetY
    }
    
    func play(at videoView: VideoPlayable, on scrollView: VideoListPlayable) {
        removeCurrentVideo(on: scrollView)
        addPlayerView(to: videoView, on: scrollView)
    }
}

private extension GXRCWVideoListAutoPlayManager {

    func relativeRect(view: UIView, relativeTo scrollView: VideoListPlayable) -> CGRect? {
        // 计算 view 相对于 scrollView 的位置
        guard let scrollViewSuperView = scrollView.superview, let containerSuperview = view.superview else {return nil}
        let containerViewRect = containerSuperview.convert(view.frame, to: scrollViewSuperView)
        let relativeRect = CGRect(origin: CGPoint(x: containerViewRect.minX - scrollView.frame.minX, y: containerViewRect.minY - scrollView.frame.minY), size: containerViewRect.size)
        return relativeRect
    }
    
    func addPlayerView(to view: VideoPlayable, on scrollView: VideoListPlayable) {

        guard let url = view.urlToPlay else {
            return
        }

        let avItem = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: avItem)
        playerVC.player = avPlayer
        avPlayer.isMuted = true//默认开启静音
        avPlayer.play()
        avPlayer.addPeriodicTimeObserver(forInterval: CMTime(value: CMTimeValue(1.0), timescale: CMTimeScale(1.0)), queue: .main) { time in
            //监听视频播放进度
            view.videoPlayTimeChanged(changeTo: CMTimeGetSeconds(time))
        }

        view.videoStatusChanged(changeTo: true)

        let containerView = view.viewToContainVideo
        containerView.addSubview(playerVC.view)

        playerVC.view.translatesAutoresizingMaskIntoConstraints = false
        playerVC.view.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        playerVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        playerVC.view.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        playerVC.view.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true

        currentPlayingView = view
        
        playerVC.showsPlaybackControls = true
    }
    
    func removeCurrentVideoIfLeavingScreen(scrollView: VideoListPlayable) {
        playerVC.showsPlaybackControls = false
        guard let view = currentPlayingView, let relativeRect = relativeRect(view: view, relativeTo: scrollView) else {
            return
        }
        let currentOffsetY = scrollView.contentOffset.y
        let containerCenterY = relativeRect.minY + relativeRect.height / 2
        if (currentOffsetY > preOffsetY && containerCenterY <= 0) || (currentOffsetY < preOffsetY && containerCenterY >= scrollView.frame.height) {
            removeCurrentVideo(on: scrollView)
        }
    }

    func removeCurrentVideo(on scrollView: VideoListPlayable) {
        playerVC.player = nil
        playerVC.view.removeFromSuperview()
        currentPlayingView?.videoStatusChanged(changeTo: false)
        currentPlayingView = nil
    }
}
