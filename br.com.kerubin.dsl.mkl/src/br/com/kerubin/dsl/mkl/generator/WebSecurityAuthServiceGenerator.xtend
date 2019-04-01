package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebSecurityAuthServiceGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val securityPath = getWebSecurityDir
		securityPath.generateAuthService
	}
	
	def generateAuthService(String securityPath) {
		val name = securityPath + 'auth.service'
		name.generateAuthServiceTS
	}
	
	def generateAuthServiceTS(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateAuthServiceTSContent)
	}
	
	def CharSequence generateAuthServiceTSContent() {
		'''
		import { JwtHelperService } from '@auth0/angular-jwt';
		import { Injectable } from '@angular/core';
		import { HttpClient, HttpHeaders } from '@angular/common/http';
		
		
		@Injectable({
		  providedIn: 'root'
		})
		export class AuthService {
		
		  oauthTokenUrl = 'http://localhost:9002/oauth/token';
		  jwtPayload: any;
		
		  constructor(
		    private http: HttpClient,
		    private jwtHelper: JwtHelperService
		    ) {
		      this.loadToken();
		  }
		
		  isAccessTokenInvalid() {
		    const token = localStorage.getItem('token');
		    return !token || this.jwtHelper.isTokenExpired(token);
		  }
		
		  refreshAccessToken(): Promise<void> {
		    const headers = new HttpHeaders()
		    .append('Content-Type', 'application/x-www-form-urlencoded')
		    .append('Authorization', 'Basic a2VydWJpbi1mZTpBbmdlbCE4MQ==');
		
		    const body = 'grant_type=refresh_token';
		
		    return this.http.post<any>(this.oauthTokenUrl, body, { headers, withCredentials: true /* for CORS */ })
		    .toPromise()
		    .then(response => {
		      console.log('!!! Atualizou access token !!!');
		      this.storeToken(response.access_token);
		      return Promise.resolve(null);
		    })
		    .catch(response => {
		      console.log('Erro ao renovar token:' + response);
		      return Promise.resolve(null); // Não conseguiu, não tem o que fazer, vai ter que fazer login.
		    });
		  }
		
		  login(username: string, password: string): Promise<void> {
		    const headers = new HttpHeaders()
		    .append('Content-Type', 'application/x-www-form-urlencoded')
		    .append('Authorization', 'Basic a2VydWJpbi1mZTpBbmdlbCE4MQ=='); // Dev da API passa isso.
		
		    const body = `username=${username}&password=${password}&grant_type=password`;
		
		    return this.http.post<any>(this.oauthTokenUrl, body, { headers, withCredentials: true })
		      .toPromise()
		      .then(response => {
		        this.storeToken(response.access_token);
		      })
		      .catch(response => {
		        return Promise.reject(response);
		      });
		  }
		
		  private storeToken(token: string) {
		    this.jwtPayload = this.jwtHelper.decodeToken(token);
		    localStorage.setItem('token', token);
		  }
		
		  private loadToken() {
		    const token = localStorage.getItem('token');
		
		    if (token) {
		      this.jwtPayload = this.jwtHelper.decodeToken(token);
		    } else {
		      // this.jwtPayload = null;
		    }
		  }
		
		}
		'''
	}
	
}