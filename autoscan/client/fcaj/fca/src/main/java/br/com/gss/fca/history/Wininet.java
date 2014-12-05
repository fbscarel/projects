package br.com.gss.fca.history;

import java.util.Arrays;
import java.util.List;

import com.sun.jna.Native;
import com.sun.jna.Structure;
import com.sun.jna.Structure.ByReference;
import com.sun.jna.Union;
import com.sun.jna.platform.win32.WinBase.FILETIME;
import com.sun.jna.platform.win32.WinNT.HANDLE;
import com.sun.jna.ptr.IntByReference;
import com.sun.jna.win32.StdCallLibrary;
import com.sun.jna.win32.W32APIOptions;

public interface Wininet extends StdCallLibrary {
	public static final Wininet INSTANCE = (Wininet) Native.loadLibrary("wininet", Wininet.class, W32APIOptions.UNICODE_OPTIONS);
	
	public static class INTERNET_CACHE_ENTRY_INFOW extends Structure implements ByReference {
		public int dwStructSize;
		public String lpszSourceUrlName;
		public String lpszLocalFileName;
		public int CacheEntryType;
		public int dwUseCount;
		public int dwHitRate;
		public int dwSizeLow;
		public int dwSizeHigh;
		public FILETIME LastModifiedTime;
		public FILETIME ExpireTime;
		public FILETIME LastAccessTime;
		public FILETIME LastSyncTime;
		public String  lpHeaderInfo;
		public int dwHeaderInfoSize;
		public UNION exemptionDelta;
		
		public INTERNET_CACHE_ENTRY_INFOW() {
			this(0);
		}
		
		public INTERNET_CACHE_ENTRY_INFOW(int memorysize) {
			if(memorysize > 0)
				allocateMemory(memorysize);
		}
		
		public static class UNION extends Union {
			public int dwReserved;
			public int dwExemptDelta;
		}  
		
		@Override
		@SuppressWarnings("rawtypes")
		protected List getFieldOrder() {
			return Arrays.asList(new String[] {
					"dwStructSize",
					"lpszSourceUrlName",
					"lpszLocalFileName",
					"CacheEntryType",
					"dwUseCount",
					"dwHitRate",
					"dwSizeLow",
					"dwSizeHigh",
					"LastModifiedTime",
					"ExpireTime",
					"LastAccessTime",
					"LastSyncTime",
					"lpHeaderInfo",
					"dwHeaderInfoSize",
					"exemptionDelta"
			});
		}
	}
	
	HANDLE FindFirstUrlCacheEntry(String filter, INTERNET_CACHE_ENTRY_INFOW info, IntByReference size);
	boolean FindNextUrlCacheEntry(HANDLE handle, INTERNET_CACHE_ENTRY_INFOW info, IntByReference size);
}
