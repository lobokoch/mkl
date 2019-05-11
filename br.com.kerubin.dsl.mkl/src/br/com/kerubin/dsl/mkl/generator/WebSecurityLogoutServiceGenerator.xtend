package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebSecurityLogoutServiceGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val securityPath = getWebSecurityDir
		securityPath.generateLogoutService
	}
	
	def generateLogoutService(String securityPath) {
		val name = securityPath + 'logout.service'
		name.generateLogoutServiceTS
	}
	
	def generateLogoutServiceTS(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateLogoutServiceTSContent)
	}
	
	def CharSequence generateLogoutServiceTSContent() {
		'''
		import { AuthService } from './auth.service';
		import { HttpClientWithToken } from './http-client-token';
		import { Injectable } from '@angular/core';
		import { environment } from 'src/environments/environment';
		
		@Injectable({
		  providedIn: 'root'
		})
		export class LogoutService {
		
		  tokensRevokeUrl = environment.apiUrl + '/tokens/revoke';
		
		  constructor(
		    private http: HttpClientWithToken,
		    private auth: AuthService
		  ) { }
		
		  logout() {
		    return this.http.delete(this.tokensRevokeUrl, { withCredentials: true })
		      .toPromise()
		      .then(() => {
		        this.auth.cleanAccessToken();
		      });
		  }
		
		}
		'''
	}
	
}