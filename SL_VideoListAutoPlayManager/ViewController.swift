//
//  ViewController.swift
//  SL_VideoListAutoPlayManager
//
//  Created by 宋亮 on 2022/11/16.
//

import UIKit

class ViewController: UIViewController {

    private var videoArr = ["https://crazynote.v.netease.com/2019/0811/6bc0a084ee8655bfb2fa31757a0570f4qt.mp4",
                            "https://dhxy.v.netease.com/2019/0813/d792f23a8da810e73625a155f44a5d96qt.mp4",
                            "https://dh2.v.netease.com/2017/cg/fxtpty.mp4",
                            "https://xy2.v.netease.com/r/video/20190814/7db8102c-1b18-4a59-ac70-ec03137f1c2e.mp4"]
    
    private var cellHArr = [500.0, 460.0, 420.0]
    
    lazy var listV: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        
        let v = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        view.addSubview(v)
        v.backgroundColor = .white
        v.dataSource = self
        v.delegate = self
        v.register(SLCollectionViewCell.self, forCellWithReuseIdentifier: "cell")

        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        listV.reloadData()
    }
}

extension ViewController: UICollectionViewDataSource,UICollectionViewDelegate{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! SLCollectionViewCell
        cell.videoUrlStr = videoArr[indexPath.item%videoArr.count]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("点击Cell")
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top:10, left: 0, bottom: 10, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.size.width, height: cellHArr[indexPath.item%cellHArr.count])
    }
}

extension ViewController: UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        GXRCWVideoListAutoPlayManager.shared.scrollViewDidScroll(listV)
    }
}

class SLCollectionViewCell: UICollectionViewCell{
    
    var videoUrlStr = ""
    
    lazy var backIV: UIImageView = {
        let iv = UIImageView()
        contentView.addSubview(iv)
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .lightGray
        iv.addSubview(playIV)
        
        return iv
    }()
    
    lazy var playIV: UIImageView = {
        let playIV = UIImageView(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        playIV.image = UIImage(named: "ic_instagram_play_haveBack")
        return playIV
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        backIV.frame = contentView.bounds
        playIV.center = backIV.center
    }
}

extension SLCollectionViewCell: VideoPlayable{
    
    var viewToContainVideo: UIView{
        return self
    }
    
    var urlToPlay: URL? {
        return URL(string: videoUrlStr)
    }
    
    func videoStatusChanged(changeTo isPlaying: Bool) {
        backIV.isHidden = isPlaying
    }
    
    func videoPlayTimeChanged(changeTo playTime: Float64) {
        
    }
}
