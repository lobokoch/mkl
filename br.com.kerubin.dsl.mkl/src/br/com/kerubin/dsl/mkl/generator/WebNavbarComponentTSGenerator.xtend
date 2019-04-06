package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class WebNavbarComponentTSGenerator extends WebNavbarComponentHTMLGenerator {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override getFileExtension() {
		'.ts'
	}
	
	override doGenerateComponent() {
		
		'''
		import { AuthService } from './../security/auth.service';
		import { Component, OnInit } from '@angular/core';
		import { LogoutService } from '../security/logout.service';
		import { MessageHandlerService } from '../core/message-handler.service';
		import { Router } from '@angular/router';
		
		// import { «service.toTranslationServiceClassName» } from '«service.serviceWebTranslationComponentPathName»';
		
		@Component({
		  selector: '«NAVBAR_SELECTOR_NAME»',
		  templateUrl: './«toWebNavbarComponentName».html',
		  styleUrls: ['./«toWebNavbarComponentName».css']
		})
		
		export class «toWebNavbarClassName» implements OnInit {
		
		  constructor(
			private authService: AuthService,
			private logoutService: LogoutService,
			private messageHandler: MessageHandlerService,
			private router: Router
		  	// private «service.toTranslationServiceVarName»: «service.toTranslationServiceClassName»
		  ) { }
		
		  ngOnInit() {
		  }
		  
		  /* 
		  «buildTranslationMethod(service)»
		  */
		  
		  getCurrentUserName() {
		      if (this.authService.jwtPayload && this.authService.jwtPayload.name) {
		        return this.authService.jwtPayload.name;
		      } else {
		        return '<Desconhecido>';
		      }
		  }
		  
		  logout() {
		      this.logoutService.logout()
		      .then(() => {
		        this.router.navigate(['/login']);
		      })
		      .catch(error => {
		        this.messageHandler.showError(error);
		      });
		  }
		
		}
		
		'''
	}
	
}