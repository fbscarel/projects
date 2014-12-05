/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package br.com.gss.fca.gui;

import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Image;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import javax.swing.ImageIcon;
import javax.swing.JPanel;

import br.com.gss.fca.Messages;
import br.com.gss.fca.gui.AbstractPanel.EVENT_TYPE;
import br.com.gss.fca.gui.impl.AnalysisPanel;
import br.com.gss.fca.gui.impl.InitPanel;

/**
 * Main window of application. It controls the Next and Previous buttons.
 * The main window changes the panel based in its current state, an instance of br.com.gss.fca.gui.StateWindow.STATE enum.
 * 
 * 
 * @author Paula.Fernandes
 */
public class MainWindow extends javax.swing.JFrame implements FeedbackDelegate, StateWindow{

	private static final long serialVersionUID = 1L;
	private STATE currentState = STATE.TERM_AGREE;

//    private javax.swing.JMenuBar menuBar;
//    private javax.swing.JMenu menuAbout;
//    private javax.swing.JMenu menuFile;

	private AbstractPanel abstractPanel;
    private javax.swing.JButton btnNext;
    private javax.swing.JButton btnPrevious;
    private javax.swing.JPanel panelButton;
    private ImagePanel panelImage;

	
	public MainWindow() {
        initComponents();
        initActions();
        refreshUIState();
        this.setBounds(250, 200, this.getWidth(), this.getHeight());
    }

    private void initActions() {
		if(btnNext!=null){
			btnNext.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					abstractPanel.onNext();
					changePanel(EVENT_TYPE.NEXT);
				}
			});
		}
		if(btnPrevious!=null){
			btnPrevious.addActionListener(new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					changePanel(EVENT_TYPE.PREVIOUS);
					abstractPanel.onPrevious();
				}
			});
		}
	}
    

	private void refreshUIState() {
		switch (currentState) {
			case TERM_AGREE:
				this.btnPrevious.setEnabled(this.abstractPanel.allowPrevious());
				this.btnNext.setEnabled(this.abstractPanel.allowNext());
				this.btnNext.setText(Messages.getString("btn.next"));
				break;
			case ANALYSIS_WAITING:
				this.btnNext.setEnabled(true);
				this.btnNext.setText(Messages.getString("btn.execute"));
				this.btnPrevious.setEnabled(true);
				break;
			case ANALYSIS_RUNNING:
				this.btnNext.setEnabled(false);
				this.btnNext.setText(Messages.getString("btn.execute"));
				this.btnPrevious.setEnabled(false);
				break;
			case ANALYSIS_ENDED:
				this.btnNext.setEnabled(true);
				this.btnNext.setText(Messages.getString("btn.finish"));
				this.btnPrevious.setEnabled(true);
				break;
		default:
			break;
		}
	}
	

	private void changePanel(AbstractPanel analysisPanel) {
		this.remove(this.abstractPanel);
		
		this.abstractPanel = analysisPanel;
		initLayout();
        
	    invalidate(); 
	    validate();
	    repaint();
	    
	    

	}

	protected void changePanel(EVENT_TYPE event) {
		switch (currentState) {
			case TERM_AGREE:
				switch (event) {
					case NEXT:
						currentState = STATE.ANALYSIS_WAITING;
						changePanel(new AnalysisPanel(this));
						break;
					case PREVIOUS:
						currentState = STATE.TERM_AGREE;
						break;
					default:
						break;
				}
				break;
			case ANALYSIS_WAITING:
				switch (event) {
					case NEXT:
						currentState = STATE.ANALYSIS_RUNNING;
						//executa analise
						break;
					case PREVIOUS:
						currentState = STATE.TERM_AGREE;
						changePanel(new InitPanel(this));
						break;
					default:
						break;
				}
				break;
			case ANALYSIS_RUNNING:
				//Não deveria entrar aqui nunca
				break;
			case ANALYSIS_ENDED:
				switch (event) {
					case NEXT:
						currentState = STATE.ENDED;
						System.exit(0);
						break;
					case PREVIOUS:
						currentState = STATE.TERM_AGREE;
						changePanel(new InitPanel(this));
						break;
					default:
						break;
				}
				break;
			default:
				break;
		}
		refreshUIState();
	}


	private void initComponents() {

		this.setTitle(Messages.getString("window.title"));
		
		panelButton = new javax.swing.JPanel();
        btnNext = new javax.swing.JButton();
        btnPrevious = new javax.swing.JButton();
        panelImage = new ImagePanel(new ImageIcon(getClass().getResource("background.png")).getImage(), 34, 404);
        abstractPanel = new InitPanel(this);
        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);

        btnNext.setText(Messages.getString("btn.next"));
        btnPrevious.setText(Messages.getString("btn.previous"));
        initLayout();
        
    }

    private void initLayout() {
    	javax.swing.GroupLayout panelButtonLayout = new javax.swing.GroupLayout(panelButton);
        panelButton.setLayout(panelButtonLayout);
        panelButtonLayout.setHorizontalGroup(
            panelButtonLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, panelButtonLayout.createSequentialGroup()
                .addContainerGap(300, Short.MAX_VALUE)
                .addComponent(btnPrevious)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addComponent(btnNext)
                .addContainerGap())
        );
        panelButtonLayout.setVerticalGroup(
            panelButtonLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, panelButtonLayout.createSequentialGroup()
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                .addGroup(panelButtonLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(btnPrevious)
                    .addComponent(btnNext))
                .addContainerGap())
        );

        javax.swing.GroupLayout panelImageLayout = new javax.swing.GroupLayout(panelImage);
        panelImage.setLayout(panelImageLayout);
        panelImageLayout.setHorizontalGroup(
            panelImageLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 27, Short.MAX_VALUE)
        );
        panelImageLayout.setVerticalGroup(
            panelImageLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 0, Short.MAX_VALUE)
        );


        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(panelImage, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(abstractPanel, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .addComponent(panelButton, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(layout.createSequentialGroup()
                        .addComponent(abstractPanel, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addComponent(panelButton, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                    .addComponent(panelImage, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addContainerGap())
        );
        
        pack();
	}

	/**
     * @param args the command line arguments
     */
    public static void main(String args[]) {

        try {
            for (javax.swing.UIManager.LookAndFeelInfo info : javax.swing.UIManager.getInstalledLookAndFeels()) {
                if ("Nimbus".equals(info.getName())) {
                    javax.swing.UIManager.setLookAndFeel(info.getClassName());
                    break;
                }
            }
        } catch (ClassNotFoundException ex) {
            java.util.logging.Logger.getLogger(MainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (InstantiationException ex) {
            java.util.logging.Logger.getLogger(MainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (IllegalAccessException ex) {
            java.util.logging.Logger.getLogger(MainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (javax.swing.UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(MainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>

        /* Create and display the form */
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                new MainWindow().setVisible(true);
            }
        });
    }


    public void refreshFeedback(){
    	refreshUIState();
    }
    

    public void onError(String error, Exception e) {
		this.abstractPanel.onError(error, e);
	}

	public void onFeedback(String message) {
		this.abstractPanel.onFeedback(message);
	}

	public STATE getCurrentState() {
		return currentState;
	}

	public void setNewState(STATE newState) {
		switch (getCurrentState()) {
			case ANALYSIS_WAITING:
				if(newState==STATE.ANALYSIS_RUNNING){
					this.currentState = newState;
				}
				break;
			case ANALYSIS_RUNNING:
				if(newState==STATE.ANALYSIS_ENDED){
					this.currentState = newState;
				}
				break;
		default:
			break;
		}
		refreshFeedback();
	}

	public void showPopupDialog(String message) {
		this.abstractPanel.showPopupDialog(message);
	}

	public RETURN_CONFIRMATION showConfirmationDialog(String message) {
		return this.abstractPanel.showConfirmationDialog(message);
	}

	
	class ImagePanel extends JPanel {
		private static final long serialVersionUID = 1L;
		private Image img;

		public ImagePanel(Image img, int width, int height) {
			this.img = img;
			Dimension size = new Dimension(width, height);
			setPreferredSize(size);
			setMinimumSize(size);
			setMaximumSize(size);
			setSize(size);
			setLayout(null);
		}

		public void paintComponent(Graphics g) {
			g.drawImage(img, 0, 0, null);
		}
	}


}
