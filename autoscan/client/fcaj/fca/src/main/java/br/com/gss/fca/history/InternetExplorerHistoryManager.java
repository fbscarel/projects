package br.com.gss.fca.history;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang3.Validate;

import br.com.gss.fca.Messages;
import br.com.gss.fca.history.HistoryItem.Browser;
import br.com.gss.fca.history.Wininet.INTERNET_CACHE_ENTRY_INFOW;

public class InternetExplorerHistoryManager implements HistoryManager {
	
	private WininetWrapper wininet;
	private List<HistoryItem> historyList;
	private Pattern urlExtracPattern;
	private Pattern httpPattern;
	
	public InternetExplorerHistoryManager() {
		urlExtracPattern = Pattern.compile(".*@(.*)");
		httpPattern = Pattern.compile("^(http|https).*");
	}
	
	private List<HistoryItem> getHistoryList() {
		if(historyList == null) {
			historyList = new ArrayList<HistoryItem>();
			INTERNET_CACHE_ENTRY_INFOW interntCache = getWininet().findFirstUrlCacheInfo(WininetWrapper.CacheFilter.VISITED);
			while(interntCache != null) {
				historyList.add(makeHistoryItem(interntCache));
				interntCache = getWininet().findNextUrlCacheInfo();
			}
		}
		getWininet().close();
		return historyList;
	}
	
	private HistoryItem makeHistoryItem(INTERNET_CACHE_ENTRY_INFOW info) {
		if(info == null)
			return null;
		
		HistoryItem item = new HistoryItem();
		item.setBrowser(Browser.INTERNET_EXPLORER);
		item.setUrl(extract(info.lpszSourceUrlName));
		item.setVisitTime(info.LastAccessTime.toDate());
		
		return item;
	}
	
	private String extract(String srcUrl){
		Matcher matcher = urlExtracPattern.matcher(srcUrl);
		if(matcher.find())
			return matcher.group(1);
		
		return null;
	}
	
	public List<HistoryItem> getHistory(Date startDate, Date endDate) {
		Validate.notNull(startDate, Messages.getString("error.not.null", new String[]{"startDate"}));
		Validate.notNull(endDate, Messages.getString("error.not.null", new String[]{"endDate"}));
		
		List<HistoryItem> filteredHistory = new ArrayList<HistoryItem>();
		List<HistoryItem> history = getHistoryList();
		for(HistoryItem item:history) {
			long visitTime = item.getVisitTime().getTime();
			if(visitTime >= startDate.getTime() && visitTime <= endDate.getTime() && httpPattern.matcher(item.getUrl()).matches())
				filteredHistory.add(item);
		}
		
		return filteredHistory;
	}
	
	public WininetWrapper getWininet() {
		if(wininet == null || wininet.isClosed())
			wininet = new WininetWrapper();
		return wininet;
	}
}
