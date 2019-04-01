package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebSecurityLoginGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val securityPath = getWebSecurityDir
		securityPath.generateLogin
	}
	
	def generateLogin(String securityPath) {
		val loginComponentName = securityPath + 'login/login.component'
		loginComponentName.generateLoginCSS
		loginComponentName.generateLoginHTML
		loginComponentName.generateLoginTS
	}
	
	def generateLoginTS(String loginComponentName) {
		val fileName = loginComponentName + '.ts'
		generateFile(fileName, generateLoginTSContent)
	}
	
	def CharSequence generateLoginTSContent() {
		'''
		import { Component, OnInit } from '@angular/core';
		import { Router } from '@angular/router';
		import { AuthService } from '../auth.service';
		import { MessageHandlerService } from 'src/app/core/message-handler.service';
		
		@Component({
		  selector: 'app-login',
		  templateUrl: './login.component.html',
		  styleUrls: ['./login.component.css']
		})
		export class LoginComponent implements OnInit {
		
		  constructor(
		    private auth: AuthService,
		    private messageHandler: MessageHandlerService,
		    private router: Router
		    ) { }
		
		  ngOnInit() {
		  }
		
		  login(username: string, password: string) {
		    this.auth.login(username, password)
		    .then(() => {
		      this.router.navigate(['/mainmenu']);
		    })
		    .catch (error => {
		      this.messageHandler.showError(error);
		    });
		  }
		
		}
		'''
	}
	
	def generateLoginHTML(String loginComponentName) {
		val fileName = loginComponentName + '.html'
		generateFile(fileName, generateLoginHTMLContent)
	}
	
	def CharSequence generateLoginHTMLContent() {
		'''
		<div class="container" style="max-width: 400px; margin: auto">
		    <!--{{ auth.jwtPayload | json }}-->
		
		    <form #loginForm="ngForm">
		      <div class="ui-g ui-fluid">
		
		        <div class="ui-g-12">
		          <h1>Acessar o Kerubin</h1>
		        </div>
		
		        <div class="ui-g-12">
		            <div class="ui-inputgroup">
		                <span class="ui-inputgroup-addon"><i class="pi pi-user"></i></span>
		                <input pInputText type="email" name="username" placeholder="Seu e-mail" ngModel required #username>
		            </div>
		        </div>
		
		        <div class="ui-g-12">
		            <div class="ui-inputgroup">
		                <span class="ui-inputgroup-addon"><i class="pi pi-key"></i></span>
		              <input pInputText type="password" name="password" placeholder="Sua senha" ngModel required #password>
		            </div>
		        </div>
		
		        <div class="ui-g-12">
		          <button pButton type="submit" label="Entrar"
		            [disabled]="!loginForm.valid"
		            (click)="login(username.value, password.value); password.value = '';">
		          </button>
		        </div>
		
		        <div class="ui-g-12">
		          <div class="ui-g-12 ui-fluid ui-md-6">
		            <a routerLink="/mainmenu" pButton class="ui-button-success" label="Criar nova conta"></a>
		          </div>
		
		          <div class="ui-g-12 ui-fluid ui-md-6">
		            <a routerLink="/mainmenu" pButton style="border: 1px solid silver" class="ui-button-secondary" label="Recuperar conta"></a>
		          </div>
		        </div>
		
		      </div>
		    </form>
		
		  </div>
		'''
	}
	
	def generateLoginCSS(String loginComponentName) {
		val fileName = loginComponentName + '.css'
		generateFile(fileName, generateLoginCSSContent)
	}
	
	def CharSequence generateLoginCSSContent() {
		'''
		/* CSS heare */ 
		'''
	}
	
}