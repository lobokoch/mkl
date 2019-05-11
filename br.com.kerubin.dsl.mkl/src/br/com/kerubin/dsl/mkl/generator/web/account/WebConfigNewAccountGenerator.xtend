package br.com.kerubin.dsl.mkl.generator.web.account

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.BaseGenerator

class WebConfigNewAccountGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	static val CONFIG_NEW_ACCOUNT = 'confignewaccount'
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val path = getWebAccountDir + '/' + CONFIG_NEW_ACCOUNT 
		path.doGenerate
	}
	
	def doGenerate(String path) {
		val componentName = path + '/' + CONFIG_NEW_ACCOUNT + '.component'
		componentName.generateCSS
		componentName.generateHTML
		componentName.generateTS
	}
	
	def generateTS(String componentName) {
		val fileName = componentName + '.ts'
		generateFile(fileName, generateTSContent)
	}
	
	def CharSequence generateTSContent() {
		'''
		import { Component, OnInit } from '@angular/core';
		
		@Component({
		  selector: 'app-confignewaccount',
		  templateUrl: './confignewaccount.component.html',
		  styleUrls: ['./confignewaccount.component.css']
		})
		export class ConfigNewAccountComponent implements OnInit {
		
		  constructor() { }
		
		  ngOnInit() {
		  }
		
		}
		'''
	}
	
	def generateHTML(String componentName) {
		val fileName = componentName + '.html'
		generateFile(fileName, generateHTMLContent)
	}
	
	def CharSequence generateHTMLContent() {
		'''
		<div class="container" style="max-width: 400px; margin: auto">
		
		    <div class="ui-g ui-fluid">
		
		      <div class="ui-g-12">
		          <h3>Você deve solicitar permissão de acesso ao administrador da conta corporativa.</h3>
		      </div>
		
		  </div>
		</div>
		'''
	}
	
	def generateCSS(String componentName) {
		val fileName = componentName + '.css'
		generateFile(fileName, generateCSSContent)
	}
	
	def CharSequence generateCSSContent() {
		'''
		/* CSS heare */ 
		'''
	}
	
}