//
//  VideoListViewController.swift
//  StreamEase Play
//
//  Created by Unique Consulting Firm on 22/12/2024.
//

import UIKit
import AVKit
import MobileCoreServices
import AVFoundation
import Photos

class VideoListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addbtn: UIButton!
    @IBOutlet weak var noVideosLabel: UILabel!
    
    var videos: [String] = []
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        roundCorner(button: addbtn)
        noVideosLabel.isHidden = true
        // Load saved videos from UserDefaults
        if let savedVideos = UserDefaults.standard.array(forKey: "SavedVideos") as? [String] {
            videos = savedVideos
        }
        
        // Configure background audio playback
              let session = AVAudioSession.sharedInstance()
              do {
                  try session.setCategory(.playback, mode: .moviePlayback, options: .allowAirPlay)
                  try session.setActive(true)
              } catch {
                  print("Error setting up audio session: \(error)")
              }
        
        updateVideoList()
    }
    
    func updateVideoList() {
        if videos.isEmpty {
            noVideosLabel.isHidden = false // Make the label visible if there are no videos
        } else {
            noVideosLabel.isHidden = true // Hide the label if there are videos
        }
    }

    // MARK: - Add Video
    @IBAction func addVideo(_ sender: Any) {
        requestPhotoLibraryPermission()
    }
    
    func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                // Permission granted, proceed with photo picker
                DispatchQueue.main.async {
                    self.showImagePicker()
                }
            case .denied, .restricted:
                // Permission denied or restricted
                DispatchQueue.main.async {
                    self.showPermissionDeniedAlert()
                }
            case .notDetermined:
                // If permission is not determined yet
                break
            @unknown default:
                break
            }
        }
    }
    
    func showPermissionDeniedAlert() {
        let alert = UIAlertController(title: "Permission Denied", message: "We need access to your photo library to select videos. Please enable it in Settings.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    
    func showImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func settingsbtnPressed(_ sender: Any) {
      let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
       let newViewController = storyBoard.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
       newViewController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
       newViewController.modalTransitionStyle = .crossDissolve
       self.present(newViewController, animated: true, completion: nil)
    }

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationURL = documentsPath.appendingPathComponent(videoURL.lastPathComponent)

            do {
                try FileManager.default.copyItem(at: videoURL, to: destinationURL)
                videos.append(videoURL.lastPathComponent) // Save only the file name
                UserDefaults.standard.set(videos, forKey: "SavedVideos")
                tableView.reloadData()
                updateVideoList()
            } catch {
                print("Error copying file: \(error)")
            }
        }
        updateVideoList()
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Helper Method to Reconstruct Full Path
    func fullPath(for fileName: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(fileName)
    }

    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! videoTableViewCell
        cell.titlelb.text = "Video \(indexPath.row + 1)"
        
        let videoURL = fullPath(for: videos[indexPath.row])

        if let thumbnail = generateThumbnail(for: videoURL) {
            cell.videoimage.image = thumbnail
        } else {
            cell.videoimage.image = UIImage(systemName: "video")
        }

        return cell
    }

    // MARK: - Play Video
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let videoURL = fullPath(for: videos[indexPath.row])
                
                // Set up the player and player view controller
                player = AVPlayer(url: videoURL)
                playerViewController = AVPlayerViewController()
                playerViewController?.player = player
                
                // Show the thumbnail first
                let thumbnailView = UIImageView(image: generateThumbnail(for: videoURL))
                thumbnailView.frame = self.view.bounds
                thumbnailView.contentMode = .scaleAspectFit
                self.view.addSubview(thumbnailView)

                // Add observer for when the video finishes playing
                NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)

                // Present player after the thumbnail, then hide the thumbnail and show the player view
                present(playerViewController!, animated: true) {
                    thumbnailView.removeFromSuperview() // Hide thumbnail when playback starts
                    self.player?.play()
                }
    }
    
    // MARK: - Video Finish Notification Handler
     @objc func videoDidFinishPlaying(notification: Notification) {
         if let currentIndex = tableView.indexPathForSelectedRow?.row {
             let nextIndex = (currentIndex + 1) % videos.count  // Loop back to first video when the last one ends
             let nextVideoURL = fullPath(for: videos[nextIndex])
             
             player?.replaceCurrentItem(with: AVPlayerItem(url: nextVideoURL))
             player?.play()  // Automatically play the next video
         }
     }

    // MARK: - Delete Video
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            videos.remove(at: indexPath.row)
            UserDefaults.standard.set(videos, forKey: "SavedVideos")
            tableView.deleteRows(at: [indexPath], with: .automatic)
            updateVideoList()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func generateThumbnail(for url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("File does not exist at path: \(url.path)")
            return nil
        }

        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
}
