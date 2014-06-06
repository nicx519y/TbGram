package ui.sticker
{
	import com.imagelib.ImageMerger;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	
	import ui.basic.MyTransformer;
	import ui.viewport.Viewport;
	
	public class Sticker extends MyTransformer
	{
		public static const EVENT_ACTIVE_CHANGE:String = 'active_change';
		public static const EVENT_SIZE_CHANGE:String = 'size_change';
		public static const EVENT_ANGLE_CHANGE:String = 'angle_change';
		public static const EVENT_READY:String = 'ready';
		public static const EVENT_DISPOSE:String = 'dispose';
		
		public static const FLIP_DIRCTION_VERTICAL:String = 'vertical';			//垂直翻转
		public static const FLIP_DIRCTION_HORIZONTAL:String = 'horizontal';		//水平翻转
		private static const _defaultScale:Number = 0.5;
		
		private var _itemConfig:Object;
		private var _loader:Loader;
		private var _minScale:Number;
		private var _maxScale:Number;
		private var _parent:Viewport;
		private var _isReady:Boolean = false;			//资源是否加载完毕
		
		public function Sticker(
			parent:Viewport,
			itemConfig:Object,
            minScale:Number=0,
			maxScale:Number=1
		) {
			_parent = parent;
			_itemConfig = itemConfig;
			_minScale = minScale;
			_maxScale = maxScale;
			
            _loader = new Loader();
            _loader.contentLoaderInfo.addEventListener(Event.COMPLETE, _imageLoaded);
			
			super();
			
			_loader.load(new URLRequest(_itemConfig.url));
		}
		
        private function _imageLoaded(event:Event):void
        {
			event.target.removeEventListener(Event.COMPLETE, _imageLoaded);
			
			this.init(
				_loader, _loader.content.width, _loader.content.height, 
				_parent, _getViewportScale(_defaultScale), _currentRotation, 
				_getViewportScale(_minScale), _getViewportScale(_maxScale)
			);
			
			_container.x = _parent.width / 2;
			_container.y = _parent.height / 2;
			
			_parent.addEventListener(Event.CHANGE, _targetChangeHandler);
			
			this._isReady = true;
			this.active = true;
			this.dispatchEvent(new Event(EVENT_READY));
        }
		private function _getViewportScale(scale:Number):Number
		{
			return scale * _parent.viewportScale;
		}
		/**
		 * previewer改变后，重新计算sticker的缩放
		 */
		private function _targetChangeHandler(evt:Event):void
		{
			this._updateCurrentRect();
			setTransform(_currentScale, _currentRotation, _isFlipedH, _isFlipedV);
		}
		
		/**
		 * 获取源素材
		 */
        public function get source():BitmapData
        {
            return ((_target as Loader).content as Bitmap).bitmapData;
        }
		/**
		 * 合成到原图
		 */
		public function merge():void
		{
			var rect:Rectangle = this.currentOriginalRect;
			var tempSource:BitmapData = ImageMerger.merge(
				_parent.getOriginalSourceCopyAt(0), 
				this.source, rect,
				this.currentScale,
				this.currentScale,
				this.currentRotation,
				this.currentAlpha,
				this.isFlipedH,
				this.isFlipedV
			);
			_parent.setSource(tempSource, 0, tempSource.width, tempSource.height, true);
		}
		public function get currentOriginalRect():Rectangle
		{
			var centerPoint:Point = _getCenterPoint(),
				viewRect:Rectangle = _parent.viewportRect,
				viewportScale:Number = _parent.viewportScale,
				w:Number = _originalWidth,
				h:Number = _originalHeight;
			
			return new Rectangle(-w/2 + (centerPoint.x - viewRect.x) / viewportScale, -h/2 + (centerPoint.y - viewRect.y) / viewportScale, w, h);
		}
 		
		public function get isReady():Boolean
		{
			return _isReady;
		}
		override public function set currentScale(scale:Number):void
		{
			super.currentScale = _getViewportScale(scale);
		}
		override public function get currentScale():Number
		{
			return _currentScale / _parent.viewportScale;
		}
		
		/**
		 * 销毁
		 */
		override public function dispose():void
		{
			(_target as Loader).unloadAndStop(true);
			
			_parent.removeEventListener(Event.CHANGE, _targetChangeHandler);
			
			super.dispose();
		}
	}
}