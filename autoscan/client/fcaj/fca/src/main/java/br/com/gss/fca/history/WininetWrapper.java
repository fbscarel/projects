package br.com.gss.fca.history;

import br.com.gss.fca.Messages;
import br.com.gss.fca.history.Wininet.INTERNET_CACHE_ENTRY_INFOW;

import com.sun.jna.platform.win32.Kernel32;
import com.sun.jna.platform.win32.WinNT.HANDLE;
import com.sun.jna.ptr.IntByReference;

public class WininetWrapper {
	public static enum CacheFilter{
		VISITED("visited:"), COOKIE("cookie:");
		
		private String filter;
		
		private CacheFilter(String filter) {
			this.filter = filter;
		}
		
		public String getFilter(){
			return filter;
		}
	};
	
	private HANDLE handle;
	private boolean closed;
	
	public WininetWrapper(){
		closed = false;
	}
	
	public INTERNET_CACHE_ENTRY_INFOW findFirstUrlCacheInfo(CacheFilter filter) {
		if(closed)
			throw new IllegalStateException(Messages.getString("error.wininet.closed"));
		
		// Get buffer size
		INTERNET_CACHE_ENTRY_INFOW info = new INTERNET_CACHE_ENTRY_INFOW();
		IntByReference size = new IntByReference(0);
		Wininet.INSTANCE.FindFirstUrlCacheEntry(filter.getFilter(), null, size);
		
		// Alloc memory and get object
		info = new INTERNET_CACHE_ENTRY_INFOW(size.getValue());
		HANDLE handle = Wininet.INSTANCE.FindFirstUrlCacheEntry(filter.getFilter(), info, size);
		if(handle != null) {
			this.handle = handle;
			return info;
		}
		
		return null;
	}
	
	public INTERNET_CACHE_ENTRY_INFOW findNextUrlCacheInfo() {
		if(handle == null)
			throw new IllegalStateException(Messages.getString("error.wininet.state"));
		if(closed)
			throw new IllegalStateException(Messages.getString("error.wininet.closed"));
		
		// Get buffer size
		INTERNET_CACHE_ENTRY_INFOW info = new INTERNET_CACHE_ENTRY_INFOW();
		IntByReference size = new IntByReference(0);
		Wininet.INSTANCE.FindNextUrlCacheEntry(handle, null, size);
		
		// Alloc memmory and get object
		info = new INTERNET_CACHE_ENTRY_INFOW(size.getValue());
		if(Wininet.INSTANCE.FindNextUrlCacheEntry(handle, info, size)){
			return info;
		}
		
		return null;
	}
	
	public void close() {
		if(!closed)
			Kernel32.INSTANCE.CloseHandle(handle);
		closed = true;
	}
	
	public boolean isClosed(){
		return closed;
	}
}
