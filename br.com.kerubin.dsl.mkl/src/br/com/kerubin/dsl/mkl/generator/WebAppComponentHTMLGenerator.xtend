package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebAppComponentHTMLGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateComponent
	}
	
	def generateComponent() {
		val path = webAppDir
		val filePath = path + toWebAppComponentName() + '.html'
		generateFile(filePath, generateAppComponent)
	}
	
	def CharSequence generateAppComponent() {
		'''
		<«NAVBAR_SELECTOR_NAME» *ngIf="canShowMenu()"></«NAVBAR_SELECTOR_NAME»>
		
		<div class="ui-g">
		  <div class="ui-g-12 ui-fluid">
		    <div class="ui-g-12 ui-fluid ui-md-2">
		      <app-kerubin-menu *ngIf="canShowMenu()"></app-kerubin-menu>
		    </div>
		
		    <div class="ui-g-12 ui-fluid ui-md-10">
		      <router-outlet></router-outlet>
		    </div>
		
		    <p-toast></p-toast>
		
		    <p-confirmDialog header="Confirmação" icon="fa fa-question-circle" #confirmacao>
		      <p-footer>
		        <button type="button" pButton label="Sim" (click)="confirmacao.accept()"></button>
		        <button type="button" pButton label="Não" (click)="confirmacao.reject()"></button>
		      </p-footer>
		    </p-confirmDialog>
		  </div>
		</div>
		
		'''
	}
	
}