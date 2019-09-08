//
//  MinimalGLViewController.swift
//  MinimalGLFramework
//
//  Created by George Corney on 08/09/2019.
//  Copyright © 2019 Haxiomic. All rights reserved.
//

import GLKit

/**
 * An OpenGL that hosts our MinimalGL example
 */
public class MinimalGLViewController: GLKViewController {
    
    public var minimalGL: MinimalGL?;
    public var context: EAGLContext?
    
    deinit {
        tearDownGL()
    }
    
    private func setupGL() {
        // Create an OpenGL ES context and store it in our local variable.
        context = EAGLContext(api: .openGLES3)
        
        // Set the current EAGLContext to our context we created when performing OpenGL setup.
        EAGLContext.setCurrent(context)
        
        // Perform checks and unwrap options in order to perform more OpenGL setup.
        if let view = self.view as? GLKView, let context = context {
            // Set our view's context to the EAGLContext we just created.s
            view.context = context
        }
        
        self.preferredFramesPerSecond = 60;
    }
    
    
    /// Perform cleanup, and delete buffers and memory.
    private func tearDownGL() {
        // Set the current EAGLContext to our context. This ensures we are deleting buffers against it and potentially not a
        // different context.
        EAGLContext.setCurrent(context)
        
        // Set the current EAGLContext to nil.
        EAGLContext.setCurrent(nil)
        
        // Then nil out or variable that references our EAGLContext.
        context = nil
    }
    
    override public func glkView(_ view: GLKView, drawIn rect: CGRect) {
        // initialize minimalGL on first frame because the view's drawable is fully initialized
        // we also rely on the screen framebuffer being bound during initialization
        if minimalGL == nil {
            minimalGL = MinimalGL(view: view);
        }
        
        // let frameTime_s = CACurrentMediaTime()
        
        minimalGL!.frame()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupGL()
    }
}
