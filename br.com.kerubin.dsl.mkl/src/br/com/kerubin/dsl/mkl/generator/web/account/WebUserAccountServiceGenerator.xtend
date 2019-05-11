package br.com.kerubin.dsl.mkl.generator.web.account

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.BaseGenerator

class WebUserAccountServiceGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	static val USER_ACCOUNT_SERVICE = 'useraccount.service'
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val path = getWebAccountDir 
		path.doGenerate
	}
	
	def doGenerate(String path) {
		val userAccount = path + '/' + USER_ACCOUNT_SERVICE
		userAccount.generateUserAccountService
	}
	
	def generateUserAccountService(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateUserAccountService)
	}
	
	def CharSequence generateUserAccountService() {
		'''
		import { HttpClientWithToken } from '../security/http-client-token';
		
		import { Injectable } from '@angular/core';
		import { HttpClient, HttpHeaders } from '@angular/common/http';
		
		import { UserAccount, AccountCreatedDTO, SysUser } from './newaccount/useraccount.model';
		import { environment } from 'src/environments/environment';
		
		@Injectable()
		export class UserAccountService {
		
			url = environment.apiUrl + '/account';
		
			constructor(
		    private http: HttpClientWithToken
		  ) { }
		
			createAccount(userAccount: UserAccount): Promise<AccountCreatedDTO> {
			    return this.http.post<AccountCreatedDTO>(`${this.url}/createAccount`, userAccount)
			    .toPromise()
			    .then(response => {
		        console.log('response: ' + response);
			      return response;
			    });
		  }
		
			confirmAccount(id: String): Promise<SysUser> {
			    return this.http.put<SysUser>(`${this.url}/confirmAccount/${id}`, {})
			    .toPromise()
			    .then(response => {
		        console.log('response: ' + response);
		        const confirmedUser = response as SysUser;
		        console.log('confirmedUser: ' + confirmedUser);
			      return confirmedUser;
			    });
			}
		}
		
		'''
	}
	
	
}