package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebAppComponentTSGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
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
		val filePath = path + toWebAppComponentName() + '.ts'
		generateFile(filePath, generateAppComponent)
	}
	
	def CharSequence generateAppComponent() {
		'''
		import { Router } from '@angular/router';
		import { Component } from '@angular/core';
		
		@Component({
		  selector: 'app-root',
		  templateUrl: './app.component.html',
		  styleUrls: ['./app.component.css']
		})
		
		export class AppComponent {
		  title = 'Kerubin';
		  urls = ['/login', '/newaccount', '/confirmaccount'];
		  constructor(private router: Router) {
		    //
		  }
		
		  canShowMenu() {
		    const url = this.router.url.toLowerCase();
		    const exists = this.urls.some(it => url.includes(it));
		    return !exists;
		  }
		}
		
		'''
	}
	
}