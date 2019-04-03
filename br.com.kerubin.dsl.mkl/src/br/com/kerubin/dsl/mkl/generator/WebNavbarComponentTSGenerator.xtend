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
		// import { «service.toTranslationServiceClassName» } from '«service.serviceWebTranslationComponentPathName»';
		
		@Component({
		  selector: '«NAVBAR_SELECTOR_NAME»',
		  templateUrl: './«toWebNavbarComponentName».html',
		  styleUrls: ['./«toWebNavbarComponentName».css']
		})
		
		export class «toWebNavbarClassName» implements OnInit {
		
		  constructor(
		  	private authService: AuthService
		  	// private «service.toTranslationServiceVarName»: «service.toTranslationServiceClassName»
		  ) { }
		
		  ngOnInit() {
		  }
		  
		  /* 
		  «buildTranslationMethod(service)»
		  */
		  
		  getCurrentUserName() {
		      if (this.authService.jwtPayload && this.authService.jwtPayload.nome) {
		        return this.authService.jwtPayload.nome;
		      } else {
		        return '<Desconhecido>';
		      }
		  }
		
		}
		
		'''
	}
	
}