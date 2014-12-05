package br.com.gss.fca.gui;

/**
 * Interface defines what are the possibles states of the Main Window.
 * It exposes methods that can change the state of the Main Window and its panels. 
 * This interface should be only used by JPanels that implement br.com.gss.fca.gui.AbstractPanel.
 * @author Paula.Fernandes
 */
public interface StateWindow {
	
	enum STATE { 
		TERM_AGREE, 
		ANALYSIS_WAITING, 
		ANALYSIS_RUNNING, 
		ANALYSIS_ENDED, 
		ENDED
	};
	
	public STATE getCurrentState();
	public void setNewState(STATE newState);
}
