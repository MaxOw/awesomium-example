{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveGeneric, DefaultSignatures #-}
module Main where

import System.IO
import Data.IORef
import Data.Label
import Control.Monad (when)
import Control.Applicative ((<$>))
import Data.Aeson.Types
import GHC.Generics

import Graphics.Rendering.OpenGL hiding (get, set)
import Graphics.UI.GLUT hiding (get, set)
import qualified Graphics.UI.GLUT as GL
import Graphics.UI.Awesomium as Awesomium hiding (print)
import Graphics.UI.Awesomium.GLUT

----------------------------------------------------------------------

data SimpleState = SimpleState
   { _stLastTime      :: Int
   , _stRotation      :: GLdouble
   , _stSpeed         :: GLdouble
   , _stSize          :: GLdouble
   , _stColor         :: Color3 GLdouble
   , _stRedColor      :: Bool }

mkLabels[''SimpleState]

----------------------------------------------------------------------

main :: IO ()
main = do
    et <- GL.get elapsedTime
    state <- newIORef $ SimpleState et 0 0 40 (Color3 1 1 1) False
    initView state >>= initInput
    idleCallback $= Just (idle state)
    mainLoop

idle :: IORef SimpleState -> IO ()
idle state = do
    st <- readIORef state
    et <- GL.get elapsedTime
    let dt = fromIntegral $ et - (get stLastTime st)
    let nr = get stRotation st - get stSpeed st * dt
    modifyIORef state 
        $ set stLastTime et
        . set stRotation nr
    postRedisplay Nothing

----------------------------------------------------------------------

initInput :: WebView -> IO ()
initInput wv = do
    motionCallback $= Just (injectMouseMotionGLUT wv)
    passiveMotionCallback $= Just (injectMouseMotionGLUT wv)
    keyboardMouseCallback $= Just (injectKeyboardMouseGLUT wv)

----------------------------------------------------------------------

initView :: IORef SimpleState -> IO WebView
initView state = do
    (progname, _) <- getArgsAndInitialize
    initialDisplayMode $= [DoubleBuffered]
    
    createWindow "awesomium-example"
    fullScreen
    
    polygonMode $= (Fill, Line)
    
    (Size sw sh) <- GL.get screenSize
    viewport $= (Position 0 0, Size sw sh)
    
    matrixMode $= Projection
    loadIdentity
    ortho2D 0 (fromIntegral sw) 0 (fromIntegral sh)
    
    currentRasterPosition $= (Vertex4 0.0 (fromIntegral sh) 0.0 1.0)
    pixelZoom $= (1.0, (-1.0))
    
    blend $= Enabled
    blendFunc $= (One, OneMinusSrcAlpha)
    
    wv <- initAwe state
    displayCallback $= (display wv state)
    return wv

display :: WebView -> IORef SimpleState -> IO ()
display wv state = do
    st <- readIORef state
    clear [ColorBuffer, DepthBuffer]
    matrixMode $= Modelview 0
    loadIdentity
    
    (Size sw sh) <- GL.get screenSize
    let (x, y) = (fromIntegral sw / 2, fromIntegral sh / 2)
    translate $ Vector3 x y (0 :: GLdouble)
    rotate (get stRotation st) $ Vector3 0 0 1
    color $ get stColor st
    let s = get stSize st
    renderPrimitive Quads $ do
        vertex $ Vertex3 (-s) (-s) 0
        vertex $ Vertex3 ( s) (-s) 0
        vertex $ Vertex3 ( s) ( s) 0
        vertex $ Vertex3 (-s) ( s) 0
    
    -- Render Awesomium
    update
    rb <- render wv
    raw <- getBuffer rb
    w <- fmap fromIntegral $ getWidth rb
    h <- fmap fromIntegral $ getHeight rb
    drawPixels (Size w h) (PixelData BGRA UnsignedByte raw)
    
    flush
    swapBuffers

----------------------------------------------------------------------

initAwe :: IORef SimpleState -> IO WebView
initAwe state = do
    Awesomium.initialize (defaultConfig { logLevel = Verbose })
    (Size sw sh) <- GL.get screenSize
    let (w, h) = (fromIntegral sw, fromIntegral sh)
    wv <- createWebview w h False
    setBaseDirectory "./src"
    loadFile wv "example.html" ""
    -- Wait for the page to load
    let wait = isLoadingPage wv >>= flip when (update >> wait)
    wait
    setTransparent wv True
    focus wv
    
    -- JavaScript API
    setCallbackJS wv (handle state)
    
    createObject wv "Application"
    setObjectCallback wv "Application" "quit"
    setObjectCallback wv "Application" "test"
    setObjectCallback wv "Application" "setSpeed"
    setObjectCallback wv "Application" "setSize"
    setObjectCallback wv "Application" "setColor"
    
    return wv

handle :: IORef SimpleState
       -> WebView -> String -> String -> [Value] -> IO ()
handle state wv "Application" fn args =
    let stSet o v = modifyIORef state $ set o v in
    case fn of
        "quit" -> leaveMainLoop
        "test" ->
            fromMaybeM_ (tryParse $ showPerson) $ maybeHead args
        "setSpeed" ->
            fromMaybeM_ (tryParse $ stSet stSpeed) $ maybeHead args
        "setSize" ->
            fromMaybeM_ (tryParse $ stSet stSize) $ maybeHead args
        "setColor" ->
            fromMaybeM_ (tryParse $ c) $ maybeHead args
                where c b = let f = stSet stColor in case b of 
                        "white" -> f $ Color3 1 1 1
                        "red"   -> f $ Color3 1 0 0
                        "green" -> f $ Color3 0 1 0
                        "blue"  -> f $ Color3 0 0 1
                        _       -> return ()
        _ -> return ()
handleActions _ _ _ _ _ = return ()

tryParse :: FromJSON a => (a -> IO ()) -> Value -> IO ()
tryParse f = either putStrLn f . parseEither parseJSON

fromMaybeM_ :: Monad m => (a -> m b) -> Maybe a -> m ()
fromMaybeM_ _ Nothing = return ()
fromMaybeM_ f (Just a) = f a >> return ()

maybeHead :: [a] -> Maybe a
maybeHead []    = Nothing
maybeHead (a:_) = Just a

data Person = Person
    { firstname :: String
    , lastname  :: String
    , age       :: Int }
    deriving (Generic, Show)

instance ToJSON Person
instance FromJSON Person

showPerson :: Person -> IO ()
showPerson = print

----------------------------------------------------------------------

