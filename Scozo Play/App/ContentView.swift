import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var sceneHolder = MenuSceneHolder()

    var body: some View {
        GeometryReader { proxy in
            SpriteView(scene: sceneHolder.scene(for: proxy.size), preferredFramesPerSecond: 60)
                .ignoresSafeArea()
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .preferredColorScheme(.dark)
    }
}

@MainActor
final class MenuSceneHolder {
    private var menu: MenuScene?

    func scene(for size: CGSize) -> SKScene {
        if let menu {
            if menu.size != size, menu.view == nil {
                menu.size = size
            }
            return menu
        }
        let scene = MenuScene(size: size)
        scene.scaleMode = .resizeFill
        menu = scene
        return scene
    }
}

#Preview {
    ContentView()
}
