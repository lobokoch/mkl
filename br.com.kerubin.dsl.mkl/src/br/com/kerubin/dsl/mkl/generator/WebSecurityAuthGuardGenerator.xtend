package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebSecurityAuthGuardGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val securityPath = getWebSecurityDir
		securityPath.generateAuthGuard
	}
	
	def generateAuthGuard(String securityPath) {
		val name = securityPath + 'auth.guard'
		name.generateAuthGuardTS
	}
	
	def generateAuthGuardTS(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateAuthGuardTSContent)
	}
	
	def CharSequence generateAuthGuardTSContent() {
		'''
		import { AuthService } from './auth.service';
		import { Injectable } from '@angular/core';
		import { CanActivate, ActivatedRouteSnapshot, RouterStateSnapshot, Router } from '@angular/router';
		import { Observable } from 'rxjs';
		
		@Injectable({
		  providedIn: 'root'
		})
		export class AuthGuard implements CanActivate {
		constructor(
		  private auth: AuthService,
		  private router: Router
		) {
		
		}
		
		  canActivate(
		    next: ActivatedRouteSnapshot,
		    state: RouterStateSnapshot): Observable<boolean> | Promise<boolean> | boolean {
		
		    if (this.auth.isAccessTokenInvalid()) {
		      console.log('AuthGuard:' + 'AcessToken inválido, obtendo novo...');
		
		      return this.auth.refreshAccessToken()
		      .then(() => {
		        if (this.auth.isAccessTokenInvalid()) {
		          this.router.navigate(['/login']);
		          return false;
		        } // if
		
		        return true;
		      });
		    } // if
		
		    return true;
		  }
		}

		'''
	}
	
}