//
//  ViewController.swift
//  map-pinned-user
//
//  Created by Luqman on 12/19/22.
//

import UIKit
import MapKit

class MapVC: UIViewController {
    let bounds = UIScreen.main.bounds
    let mapView = MKMapView()
    let pinnedAvatar  = PinnedUserView()
    var pinnedAvatarTopAnchor: NSLayoutConstraint!
    var pinnedAvatarLeadingAnchor: NSLayoutConstraint!
    var pinnedAvatarTrailingAnchor: NSLayoutConstraint!

    var avatarBounds =  AvatarBounds.inBounds {
        didSet{
            switch avatarBounds{
            case  .inBounds:
                print("INBOUNDS")
            case  .leftSide:
                print("LEFT SIDE")
            case .rightSide:
                print("RIGHT SIDE")
            }
        }
    }
    //let selfUserMapAvatar = SelfUserMapAvatarView()


    override func viewDidLoad() {
        super.viewDidLoad()
        configureMapView()
        configurePinnedAvatar()
    }

    override func viewDidAppear(_ animated: Bool) {
        zoomIntoUser()
    }

    func configurePinnedAvatar() {
        view.addSubview(pinnedAvatar)
        pinnedAvatar.alpha = 0
        pinnedAvatar.translatesAutoresizingMaskIntoConstraints = false

        pinnedAvatarTopAnchor = pinnedAvatar.topAnchor.constraint(equalTo: view.topAnchor)
        pinnedAvatarLeadingAnchor = pinnedAvatar.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        pinnedAvatarTrailingAnchor = pinnedAvatar.trailingAnchor.constraint(equalTo: view.trailingAnchor)

    }

    func zoomIntoUser() {
        if let userCoordinate = mapView.userLocation.location?.coordinate {
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: userCoordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
    }

}

extension MapVC: MKMapViewDelegate {

    func configureMapView() {
        view.addSubview(mapView)
        view.sendSubviewToBack(mapView)
        mapView.delegate = self
        mapView.overrideUserInterfaceStyle = .dark
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsUserLocation = true

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let userCGPoint = mapView.convert(mapView.userLocation.coordinate, toPointTo: mapView)
        let userView = mapView.view(for: mapView.userLocation)

        pinnedAvatarTopAnchor.isActive = true
        pinnedAvatarTopAnchor.constant = userCGPoint.y

        if userCGPoint.x <= 0 {
            if avatarBounds != .leftSide {
                avatarBounds = .leftSide
                pinnedAvatarLeadingAnchor.constant = 30
                pinnedAvatarTopAnchor.constant += 15
                pinnedAvatarLeadingAnchor.isActive = true
                pinnedAvatarTrailingAnchor.isActive = false

                UIView.animateKeyframes(withDuration: 0.47, delay: 0, animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.1, animations: {
                        self.pinnedAvatar.alpha = 1

                    })
                    UIView.addKeyframe(withRelativeStartTime: 0.05, relativeDuration: 0.22, animations: {
                        userView?.alpha = 0
                    })

                    UIView.addKeyframe(withRelativeStartTime: 0.13, relativeDuration: 0.15, animations: {
                        self.pinnedAvatar.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                        self.view.layoutIfNeeded()
                    })
                })

            }
        } else if userCGPoint.x >= bounds.size.width{
            if avatarBounds != .rightSide {
                avatarBounds = .rightSide
                pinnedAvatarTrailingAnchor.isActive = true
                pinnedAvatarLeadingAnchor.isActive = false

                UIView.animateKeyframes(withDuration: 0.32, delay: 0, animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.1, animations: {
                        self.pinnedAvatar.alpha = 1

                    })
                    UIView.addKeyframe(withRelativeStartTime: 0.05, relativeDuration: 0.22, animations: {
                        userView?.alpha = 0
                    })
                })
            }
        } else {
            if avatarBounds != .inBounds {
                pinnedAvatarTopAnchor.constant -= 15
                avatarBounds = .inBounds
                pinnedAvatarLeadingAnchor.constant = -20
                UIView.animateKeyframes(withDuration: 0.47, delay: 0, options: [.calculationModeCubicPaced], animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0.22, relativeDuration: 0.2, animations: {
                        userView?.alpha = 1
                    })
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.88, animations: {
                        self.pinnedAvatar.transform = CGAffineTransform(scaleX: 1, y: 1)
                        self.pinnedAvatar.alpha = 0

                    })
//                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.12, animations: {
//                        self.view.layoutIfNeeded()
//                    })
                })
            }
        }

    }


    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {


        if annotation.isEqual(mapView.userLocation){
            let userAnnotationView = self.selfUserAnnotationView(in: mapView, for: annotation)
            if avatarBounds == .inBounds{
                UIView.animate(withDuration: 0.5, animations: {
                    userAnnotationView.alpha = 0
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                })

            }else{
                userAnnotationView.alpha = 1
            }

            return userAnnotationView
        }
        return nil
    }


    private func selfUserAnnotationView(in mapView: MKMapView, for annotation: MKAnnotation) -> SelfUserAnnotationView {
        let identifier = "\(SelfUserAnnotationView.self)"

        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? SelfUserAnnotationView {
            annotationView.annotation = annotation
            return annotationView
        } else {
            let selfUserAnnotation = SelfUserAnnotationView(
                annotation: annotation, reuseIdentifier: identifier
            )
            selfUserAnnotation.canShowCallout = true
            return selfUserAnnotation
        }
    }
}

enum AvatarBounds {
    case leftSide
    case rightSide
    case inBounds
}
