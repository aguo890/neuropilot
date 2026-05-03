import SwiftUI

struct RasterPlotView: View {
    let history: [[Int]] // Array of spike ID lists
    let maxNeurons: Int = 100
    let maxHistory: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Neural Raster", systemImage: "waveform.path.ecg")
                    .font(.headline)
                Spacer()
                Text("\(maxNeurons) Channels")
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            
            Canvas { context, size in
                let cellWidth = size.width / CGFloat(maxHistory)
                let cellHeight = size.height / CGFloat(maxNeurons)
                
                // Draw Background Glassmorphism Grid
                let path = Path(CGRect(origin: .zero, size: size))
                context.fill(path, with: .color(Color(NSColor.windowBackgroundColor).opacity(0.5)))
                
                // Horizontal grid lines (every 20 neurons)
                for i in 0...5 {
                    let y = CGFloat(i) * (size.height / 5)
                    var linePath = Path()
                    linePath.move(to: CGPoint(x: 0, y: y))
                    linePath.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(linePath, with: .color(.gray.opacity(0.1)), lineWidth: 0.5)
                }
                
                // Vertical grid lines (every quarter of history)
                for i in 0...4 {
                    let x = CGFloat(i) * (size.width / 4)
                    var linePath = Path()
                    linePath.move(to: CGPoint(x: x, y: 0))
                    linePath.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(linePath, with: .color(.gray.opacity(0.1)), lineWidth: 0.5)
                }
                
                // Draw Spikes efficiently
                var spikeContext = context
                spikeContext.addFilter(.shadow(color: .green.opacity(0.5), radius: 1, x: 0, y: 0))
                
                var spikePath = Path()
                
                for (timeIndex, spikes) in history.enumerated() {
                    for neuronId in spikes {
                        let x = CGFloat(timeIndex) * cellWidth
                        let y = size.height - (CGFloat(neuronId) * cellHeight)
                        
                        let rect = CGRect(x: x, y: y, width: max(1.5, cellWidth), height: max(1.5, cellHeight))
                        spikePath.addRect(rect)
                    }
                }
                
                spikeContext.fill(spikePath, with: .color(.green))
            }
            .frame(minHeight: 250)
            .background(Color.black.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

#Preview {
    RasterPlotView(history: [[1, 5, 10], [2, 6, 11], [3, 7, 90]], maxHistory: 100)
        .padding()
}

// MARK: - Metal Low-Latency Renderer
// Consolidated here because this file is already in the Xcode project.

import MetalKit

struct Uniforms {
    var cursorPosition: simd_float2
    var viewportSize: simd_float2
    var cursorColor: simd_float4
    var cursorSize: Float
}

class MetalCursorRenderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState?
    
    var cursorPosition: CGPoint = .zero
    var cursorColor: NSColor = .systemBlue
    var cursorSize: Float = 20.0
    
    let shaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexOut {
        float4 position [[position]];
        float4 color;
    };

    struct Uniforms {
        float2 cursorPosition;
        float2 viewportSize;
        float4 cursorColor;
        float cursorSize;
    };

    vertex VertexOut vertex_main(uint vertexID [[vertex_id]],
                                 constant Uniforms &uniforms [[buffer(0)]]) {
        float2 p = uniforms.cursorPosition;
        float2 ndcPosition = p;
        ndcPosition.y *= -1.0;
        
        float2 offset = 0.0;
        float size = uniforms.cursorSize / uniforms.viewportSize.x;
        
        if (vertexID == 0) offset = float2(-size, 0);
        if (vertexID == 1) offset = float2(size, 0);
        if (vertexID == 2) offset = float2(0, -size);
        if (vertexID == 3) offset = float2(0, size);
        
        VertexOut out;
        out.position = float4(ndcPosition + offset, 0.0, 1.0);
        out.color = uniforms.cursorColor;
        return out;
    }

    fragment float4 fragment_main(VertexOut in [[stage_in]]) {
        return in.color;
    }
    """
    
    init?(metalView: MTKView) {
        self.device = metalView.device!
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        
        buildPipeline(metalView: metalView)
    }
    
    private func buildPipeline(metalView: MTKView) {
        do {
            let library = try device.makeLibrary(source: shaderSource, options: nil)
            let vertexFunction = library.makeFunction(name: "vertex_main")
            let fragmentFunction = library.makeFunction(name: "fragment_main")
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
            
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let pipelineState = pipelineState else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        var uniforms = Uniforms(
            cursorPosition: simd_float2(Float(cursorPosition.x), Float(cursorPosition.y)),
            viewportSize: simd_float2(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            cursorColor: simd_float4(
                Float(cursorColor.redComponent),
                Float(cursorColor.greenComponent),
                Float(cursorColor.blueComponent),
                Float(cursorColor.alphaComponent)
            ),
            cursorSize: cursorSize
        )
        
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 4)
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

struct MetalView: NSViewRepresentable {
    @Binding var cursorPosition: CGPoint
    @Binding var confidence: Double
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 120
        
        context.coordinator.renderer = MetalCursorRenderer(metalView: mtkView)
        mtkView.delegate = context.coordinator.renderer
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.renderer?.cursorPosition = cursorPosition
        let red = CGFloat(1.0 - confidence)
        let green = CGFloat(confidence)
        context.coordinator.renderer?.cursorColor = NSColor(red: red, green: green, blue: 0.2, alpha: 1.0)
    }
    
    class Coordinator: NSObject {
        var parent: MetalView
        var renderer: MetalCursorRenderer?
        init(_ parent: MetalView) { self.parent = parent }
    }
}
