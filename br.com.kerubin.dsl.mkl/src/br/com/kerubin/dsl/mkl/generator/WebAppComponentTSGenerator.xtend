package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.generator.web.analitycs.WebAnalitycsGenerator

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
		val hasWebAnalitycs = service.hasWebAnalitycs
		
		'''
		import { Router, NavigationEnd } from '@angular/router';
		import { Component } from '@angular/core';
		«IF hasWebAnalitycs»
		import { «WebAnalitycsGenerator.SERVICE_CLASS_NAME» } from './«Utils.WEB_ANALITYCS_DIR»«WebAnalitycsGenerator.SERVICE_NAME»';
		«ENDIF»
		import { AuthService } from './security/auth.service';
		
		@Component({
		  selector: 'app-root',
		  templateUrl: './app.component.html',
		  styleUrls: ['./app.component.css']
		})
		
		export class AppComponent {
		  title = 'Kerubin';
		  urls = ['/home', '/login', '/newaccount', '/confirmaccount', '/forgotpassword', '/changepasswordforgotten'];
		  constructor(
		    private router: Router,
		    «IF hasWebAnalitycs»
		    private analitycs: «WebAnalitycsGenerator.SERVICE_CLASS_NAME»,
		    «ENDIF»
		    private auth: AuthService
		    ) {
				«IF hasWebAnalitycs»
				// For Google Analitycs
				this.router.events.subscribe(event => {
					if (event instanceof NavigationEnd) {
						analitycs.sendGTag(event.urlAfterRedirects);
					}
				});
		    	«ENDIF»
		  }
		
		  canShowMenu() {
		    const url = this.router.url.toLowerCase();
		    const exists = this.urls.some(it => url.includes(it));
		    return !exists && this.auth.isLoginValid();
		  }
		
		  getRouterOutletCssClass(): string {
		    let result = 'ui-g-12 ui-fluid ui-md-10';
		    if (!this.canShowMenu()) {
		      result = 'ui-g-12 ui-fluid ui-md-12';
		    }
		
		    return result;
		  }
		
		}
		
		'''
	}
	
}