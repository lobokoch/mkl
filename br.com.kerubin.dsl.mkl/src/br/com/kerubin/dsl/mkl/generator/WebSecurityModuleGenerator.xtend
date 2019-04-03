package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebSecurityModuleGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val securityPath = getWebSecurityDir
		securityPath.generateSecurityModule
	}
	
	def generateSecurityModule(String securityPath) {
		val name = securityPath + 'security.module'
		name.generateSecurityModuleTS
	}
	
	def generateSecurityModuleTS(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateSecurityModuleTSContent)
	}
	
	def CharSequence generateSecurityModuleTSContent() {
		'''
		import { AuthGuard } from './auth.guard';
		import { NgModule } from '@angular/core';
		import { CommonModule } from '@angular/common';
		import { JwtModule } from '@auth0/angular-jwt';
		import { environment } from 'src/environments/environment';
		
		export function tokenGetter() {
		  return localStorage.getItem('token');
		}
		
		@NgModule({
		  imports: [
		    CommonModule,
		
		    JwtModule.forRoot({
		      config: {
		        tokenGetter: tokenGetter,
		        whitelistedDomains: environment.tokenWhitelistedDomains,
		        blacklistedRoutes: environment.tokenBlacklistedRoutes
		      }
		    })
		  ],
		  declarations: [],
		  providers: [
		  	AuthGuard
		  ]
		})
		export class SecurityModule { }
		
		'''
	}
	
}