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
		
		<router-outlet></router-outlet>
		
		<p-toast></p-toast>
		
		<p-confirmDialog header="Confirmação" icon="fa fa-question-circle" #confirmacao>
		    <p-footer>
		      <button type="button" pButton label="Sim" (click)="confirmacao.accept()"></button>
		      <button type="button" pButton label="Não" (click)="confirmacao.reject()"></button>
		    </p-footer>
		  </p-confirmDialog>
		'''
	}
	
}