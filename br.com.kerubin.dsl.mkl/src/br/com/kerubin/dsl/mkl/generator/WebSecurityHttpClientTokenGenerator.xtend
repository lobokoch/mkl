package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebSecurityHttpClientTokenGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val securityPath = getWebSecurityDir
		securityPath.generateHttpClientToken
	}
	
	def generateHttpClientToken(String securityPath) {
		val name = securityPath + 'http-client-token'
		name.generateHttpClientTokenTS
	}
	
	def generateHttpClientTokenTS(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateHttpClientTokenTSContent)
	}
	
	def CharSequence generateHttpClientTokenTSContent() {
		'''
		import { Injectable } from '@angular/core';
		import { HttpClient, HttpHandler } from '@angular/common/http';
		
		import { Observable, from as observableFromPromise } from 'rxjs';
		
		import { AuthService } from './auth.service';
		
		@Injectable()
		export class HttpClientWithToken extends HttpClient {
		
		  constructor(
		    private auth: AuthService,
		    private httpHandler: HttpHandler
		  ) {
		    super(httpHandler);
		  }
		
		  public delete<T>(url: string, options?: any): Observable<T> {
		    return this.interceptExecution<T>(() => super.delete<T>(url, options));
		  }
		
		  public patch<T>(url: string, body: any, options?: any): Observable<T> {
		    return this.interceptExecution<T>(() => super.patch<T>(url, options));
		  }
		
		  public head<T>(url: string, options?: any): Observable<T> {
		    return this.interceptExecution<T>(() => super.head<T>(url, options));
		  }
		
		  public options<T>(url: string, options?: any): Observable<T> {
		    return this.interceptExecution<T>(() => super.options<T>(url, options));
		  }
		
		  public get<T>(url: string, options?: any): Observable<T> {
		    return this.interceptExecution<T>(() => super.get<T>(url, options));
		  }
		
		  public post<T>(url: string, body: any, options?: any): Observable<T> {
		    return this.interceptExecution<T>(() => super.post<T>(url, body, options));
		  }
		
		  public put<T>(url: string, body: any, options?: any): Observable<T> {
		    return this.interceptExecution<T>(() => super.put<T>(url, body, options));
		  }
		
		  private interceptExecution<T>(fn: Function): Observable<T> {
		    if (this.auth.isAccessTokenInvalid()) {
		      console.log('Requisição HTTP com access token inválido. Obtendo novo token...');
		
		      const newAccessToken = this.auth.refreshAccessToken()
		        .then(() => {
		          return fn().toPromise();
		        });
		
		       return observableFromPromise(newAccessToken);
		    } else {
		      return fn();
		    }
		  }
		
		}
		'''
	}
	
}