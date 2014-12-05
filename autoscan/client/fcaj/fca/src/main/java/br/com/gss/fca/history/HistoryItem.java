package br.com.gss.fca.history;

import java.text.SimpleDateFormat;
import java.util.Date;

public class HistoryItem {
	public static enum Browser {
		INTERNET_EXPLORER, GOOGLE_CHROME, MOZILLA_FIREFOX
	}
	
	private Browser browser;
	private String url;
	private Date visitTime;
	
	public Browser getBrowser() {
		return browser;
	}
	public void setBrowser(Browser browser) {
		this.browser = browser;
	}
	public String getUrl() {
		return url;
	}
	public void setUrl(String url) {
		this.url = url;
	}
	public Date getVisitTime() {
		return visitTime;
	}
	
	public String getVisitTimeFmt() {
		SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");
		return sdf.format(visitTime);
	}
	
	public void setVisitTime(Date visitTime) {
		this.visitTime = visitTime;
	}
	
	@Override
	public String toString() {
		return String.format("HistoryItem {browser: %s, url: %s, visitTime: %s}", browser.toString(), url, getVisitTimeFmt());
	}
}
