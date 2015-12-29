package;

import openfl.geom.Point;
import openfl.geom.PerspectiveProjection;
import openfl.geom.Vector3D;
import flash.errors.Error;
import openfl.display.OpenGLView;
import openfl.display.Sprite;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;
import openfl.gl.GL;
import openfl.gl.GLBuffer;
import openfl.gl.GLProgram;
import openfl.gl.GLTexture;
import openfl.gl.GLUniformLocation;
import openfl.utils.Float32Array;
import openfl.utils.UInt8Array;
import openfl.Assets;

class Main extends Sprite {

    private var view:OpenGLView;
    private var shaderProgram:GLProgram;
    private var vertexAttribute:Int;
    private var modelViewMatrixUniform:GLUniformLocation;
    private var projectionMatrixUniform:GLUniformLocation;
    private var triangleVertexPositionBuffer:GLBuffer;
    private var squareVertexPositionBuffer:GLBuffer;

    public function new () {
        super ();

        if (!OpenGLView.isSupported) {
            throw new Error("Could not initialise OpenGL, sorry :-(");
            return;
        }

        // var canvas = document.getElementById("the-canvas");
        view = new OpenGLView ();

        initShaders();
        initBuffers();

        // This is too early to clear in OpenFL
        //gl.clearColor(0.0, 0.0, 0.0, 1.0);
        GL.clearColor (0.0, 0.0, 0.0, 1.0);
        //gl.enable(gl.DEPTH_TEST);
        GL.enable (GL.DEPTH_TEST);

        //drawScene();
        view.render = renderView;
        addChild(view);
    }

    private function initShaders():Void {

        var fragmentShader = getFragmentShader();
        var vertexShader = getVertexShader();

        //shaderProgram = gl.createProgram();
        //gl.attachShader(shaderProgram, vertexShader);
        //gl.attachShader(shaderProgram, fragmentShader);
        //gl.linkProgram(shaderProgram);
        shaderProgram = GL.createProgram ();
        GL.attachShader (shaderProgram, vertexShader);
        GL.attachShader (shaderProgram, fragmentShader);
        GL.linkProgram (shaderProgram);

        //if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
        //    alert("Could not initialise shaders");
        //}
        if (GL.getProgramParameter (shaderProgram, GL.LINK_STATUS) == 0) {
            throw "Could not initialise shaders.";
        }

        //gl.useProgram(shaderProgram);
        GL.useProgram (shaderProgram);

        //shaderProgram.vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition");
        vertexAttribute = GL.getAttribLocation (shaderProgram, "aVertexPosition");

        //gl.enableVertexAttribArray(shaderProgram.vertexPositionAttribute);
        GL.enableVertexAttribArray (vertexAttribute);

        //shaderProgram.pMatrixUniform = gl.getUniformLocation(shaderProgram, "uPMatrix");
        //shaderProgram.mvMatrixUniform = gl.getUniformLocation(shaderProgram, "uMVMatrix");
        projectionMatrixUniform = GL.getUniformLocation (shaderProgram, "uProjectionMatrix");
        modelViewMatrixUniform = GL.getUniformLocation (shaderProgram, "uModelViewMatrix");
    }

    private function getFragmentShader() {
        var fragmentShaderSource =
            #if !desktop
            "precision mediump float;" +
            #end

            "void main(void) {
				gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
			}";

        var fragmentShader = GL.createShader (GL.FRAGMENT_SHADER);
        GL.shaderSource (fragmentShader, fragmentShaderSource);
        GL.compileShader (fragmentShader);
        if (GL.getShaderParameter (fragmentShader, GL.COMPILE_STATUS) == 0) {
            throw "Error compiling fragment shader";
        }
        return fragmentShader;
    }

    private function getVertexShader() {
        var vertexShaderSource =
            "attribute vec3 aVertexPosition;
            uniform mat4 uModelViewMatrix;
            uniform mat4 uProjectionMatrix;

            void main(void) {
                gl_Position = uProjectionMatrix * uModelViewMatrix * vec4 (aVertexPosition, 1.0);
            }";

        var vertexShader = GL.createShader (GL.VERTEX_SHADER);
        GL.shaderSource (vertexShader, vertexShaderSource);
        GL.compileShader (vertexShader);
        if (GL.getShaderParameter (vertexShader, GL.COMPILE_STATUS) == 0) {
            throw "Error compiling vertex shader";
        }
        return vertexShader;
    }

    private function initBuffers():Void {
        //triangleVertexPositionBuffer = gl.createBuffer();
        triangleVertexPositionBuffer = GL.createBuffer ();
        //gl.bindBuffer(gl.ARRAY_BUFFER, triangleVertexPositionBuffer);
        GL.bindBuffer (GL.ARRAY_BUFFER, triangleVertexPositionBuffer);

        var vertices = [
            0.0, 1.0, 0.0, -1.0, -1.0, 0.0,
            1.0, -1.0, 0.0
        ];
        //gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
        GL.bufferData (GL.ARRAY_BUFFER, new Float32Array (vertices), GL.STATIC_DRAW);

        // Note: These are dynamic object work-arounds in WebGL example
        // they are now hard coded in this OpenFL exampled
        //triangleVertexPositionBuffer.itemSize = 3;
        //triangleVertexPositionBuffer.numItems = 3;

        // Todo(Hays) Why? is this needed, it is in OpenFL example but not in WebGL
        GL.bindBuffer (GL.ARRAY_BUFFER, null);

        //squareVertexPositionBuffer = gl.createBuffer();
        squareVertexPositionBuffer = GL.createBuffer ();
        //gl.bindBuffer(gl.ARRAY_BUFFER, squareVertexPositionBuffer);
        GL.bindBuffer (GL.ARRAY_BUFFER, squareVertexPositionBuffer);

        vertices = [
            1.0, 1.0, 0.0, -1.0, 1.0, 0.0,
            1.0, -1.0, 0.0, -1.0, -1.0, 0.0
        ];

        //gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
        GL.bufferData (GL.ARRAY_BUFFER, new Float32Array (vertices), GL.STATIC_DRAW);

        // Note: These are dynamic object work-arounds in WebGL example
        // they are now hard coded in this OpenFL exampled
        //squareVertexPositionBuffer.itemSize = 3;
        //squareVertexPositionBuffer.numItems = 4;

        // Todo(Hays) Why? is this needed, it is in OpenFL example but not in WebGL
        GL.bindBuffer (GL.ARRAY_BUFFER, null);
    }

    //var mvMatrix = mat4.create();
    //var pMatrix = mat4.create();
    private function renderView (rect:Rectangle):Void {
        GL.useProgram (shaderProgram);
        GL.enableVertexAttribArray (vertexAttribute);

        GL.clearColor (0.0, 0.0, 0.0, 1.0);

        //GL.enable (GL.DEPTH_TEST);
        var modelViewMatrix = Matrix3D.create2D (0, 0, 1, 0);

        //gl.viewport(0, 0, gl.viewportWidth, gl.viewportHeight);
        GL.viewport (Std.int (rect.x), Std.int (rect.y), Std.int (rect.width), Std.int (rect.height));

        //gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        GL.clear (GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

        //mat4.perspective(45, gl.viewportWidth / gl.viewportHeight, 0.1, 100.0, pMatrix);
        var projectionMatrix = makePerspective(45, (rect.width/rect.height), 0.1, 100.0);
        //mat4.identity(mvMatrix);

        // move all items to center of viewport
        //mat4.translate(mvMatrix, [-1.5, 0.0, -7.0]);
        modelViewMatrix.position = modelViewMatrix.position.add(new Vector3D(-1.5, 0.0, -7.0));

        //gl.bindBuffer(gl.ARRAY_BUFFER, triangleVertexPositionBuffer);
        //gl.vertexAttribPointer(shaderProgram.vertexPositionAttribute, triangleVertexPositionBuffer.itemSize, gl.FLOAT, false, 0, 0);
        GL.bindBuffer (GL.ARRAY_BUFFER, triangleVertexPositionBuffer);
        GL.vertexAttribPointer (vertexAttribute, 3, GL.FLOAT, false, 0, 0);

        //setMatrixUniforms();
        //gl.uniformMatrix4fv(shaderProgram.pMatrixUniform, false, pMatrix);
        //gl.uniformMatrix4fv(shaderProgram.mvMatrixUniform, false, mvMatrix);
        GL.uniformMatrix4fv (projectionMatrixUniform, false, new Float32Array (projectionMatrix.rawData));
        GL.uniformMatrix4fv (modelViewMatrixUniform, false, new Float32Array (modelViewMatrix.rawData));

        //gl.drawArrays(gl.TRIANGLES, 0, triangleVertexPositionBuffer.numItems);
        GL.drawArrays (GL.TRIANGLE_STRIP, 0, 3);

        //mat4.translate(mvMatrix, [3.0, 0.0, 0.0]);
        modelViewMatrix.position = modelViewMatrix.position.add(new Vector3D(3, 0.0, 0.0));

        //gl.bindBuffer(gl.ARRAY_BUFFER, squareVertexPositionBuffer);
        //gl.vertexAttribPointer(shaderProgram.vertexPositionAttribute, squareVertexPositionBuffer.itemSize, gl.FLOAT, false, 0, 0);
        GL.bindBuffer (GL.ARRAY_BUFFER, squareVertexPositionBuffer);
        GL.vertexAttribPointer (vertexAttribute, 3, GL.FLOAT, false, 0, 0);

        //setMatrixUniforms();
        //gl.uniformMatrix4fv(shaderProgram.pMatrixUniform, false, pMatrix);
        //gl.uniformMatrix4fv(shaderProgram.mvMatrixUniform, false, mvMatrix);
        GL.uniformMatrix4fv (projectionMatrixUniform, false, new Float32Array (projectionMatrix.rawData));
        GL.uniformMatrix4fv (modelViewMatrixUniform, false, new Float32Array (modelViewMatrix.rawData));

        //gl.drawArrays(gl.TRIANGLE_STRIP, 0, squareVertexPositionBuffer.numItems);
        GL.drawArrays (GL.TRIANGLE_STRIP, 0, 4);

        //
        GL.bindBuffer (GL.ARRAY_BUFFER, null);

        GL.disableVertexAttribArray (vertexAttribute);
        GL.useProgram (null);
    }

    private function makePerspective(fieldOfViewInRadians:Float, aspect:Float, near:Float, far:Float) {
        var f = Math.tan(Math.PI * 0.5 - 0.5 * fieldOfViewInRadians);
        var rangeInv = 1.0 / (near - far);

        return new Matrix3D([
            f / aspect, 0.0, 0.0, 0.0,
            0.0, f, 0.0, 0.0,
            0.0, 0.0, (near + far) * rangeInv, -1.0,
            0.0, 0.0, near * far * rangeInv * 2, 0.0]
        );
    }
}
