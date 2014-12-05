package br.com.gss.fca.history;

import java.util.Date;
import java.util.List;

public interface HistoryManager {
	public List<HistoryItem> getHistory(Date startDate, Date endDate);
}
