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
		// Angular
		import { FormsModule } from '@angular/forms';
		import { CommonModule } from '@angular/common';
		import { NgModule } from '@angular/core';
		import { JwtModule } from '@auth0/angular-jwt';
		
		// Kerubin - BEGIN
		import { LoginComponent } from './login/login.component';
		import { AuthService } from './auth.service';
		import { CardModule } from 'primeng/card';
		import { ButtonModule } from 'primeng/button';
		import { InputTextModule } from 'primeng/inputtext';
		import { AuthGuard } from './auth.guard';
		import { environment } from 'src/environments/environment';
		import { LogoutService } from './logout.service';
		// Kerubin - END
		
		export function tokenGetter() {
		  return localStorage.getItem('token');
		}
		
		@NgModule({
		  imports: [
		
		    JwtModule.forRoot({
		      config: {
		        tokenGetter: tokenGetter,
		        whitelistedDomains: environment.tokenWhitelistedDomains,
		        blacklistedRoutes: environment.tokenBlacklistedRoutes
		      }
		    }),
		
		    CommonModule,
		    FormsModule,
		    InputTextModule,
		    ButtonModule,
		    CardModule
		
		  ],
		
		  declarations: [
		    LoginComponent
		  ],
		
		  providers: [
		    AuthGuard,
		    AuthService,
		    LogoutService
		  ]
		})
		
		export class SecurityModule {
		
		}
		
		'''
	}
	
}